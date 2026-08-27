#!/usr/bin/env python3
"""Profile a Terrateam GitHub Actions run: where did the time go?

Takes a URL, a log file, or the logs zip GitHub gives you:

    terrateam-run-profile.py https://github.com/OWNER/REPO/actions/runs/123/job/456
    terrateam-run-profile.py logs_32825125903.zip
    terrateam-run-profile.py run.log

Reports the run's phases, the slowest steps and dirspaces, time spent talking to
the Terrateam API, and configuration signals worth acting on.
"""

import argparse
import bisect
import codecs
import collections
import os
import re
import subprocess
import sys
import textwrap
import zipfile
from datetime import datetime, timezone

# The strings below are the runner's log contract and live in
# terrateamio/action, not this repo, so they can drift independently:
#   STEP : RUN / STEP : FAIL            terrat_runner/workflow_step.py
#   cwd=<dir>                           terrat_runner/cmd.py
#   EXEC : DIR, EXEC : HOOKS : PRE/POST terrat_runner/work_exec.py
#   PLAN : RESULTS                      terrat_runner/workflow_step_plan.py
#   INIT : CREATE_AND_SELECT_WORKSPACE  terrat_runner/engine_tf.py
# If a rename lands there this script reports "Nothing to time in this input"
# and prints the marker counts it did find, which is the signal to update here.
TS = re.compile(r'(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z)')
ANSI = re.compile(r'\x1b\[[0-9;]*[A-Za-z]')
# GitHub's secret masking can rewrite the step dict's braces to ***, so take the
# rest of the line rather than insisting on a literal {...}.
STEP = re.compile(r'STEP : RUN : (\S+) : (.+?)\s*$')
STEP_FAIL = re.compile(r'STEP : FAIL : (\S+) : ')
CWD = re.compile(r'cwd=(\S+?):')
RESULTS = re.compile(r'(?:PLAN|APPLY) : RESULTS : (\S+) : (\S+) : has_changes=(\w+)')
EXEC_DIR = re.compile(r'EXEC : DIR : (\S+)')
STEP_TYPE = re.compile(r"'type':\s*'([^']+)'")
STEP_CMD = re.compile(r"'cmd':\s*\[([^\]]*)\]")
STEP_NAME = re.compile(r"'name':\s*'([^']+)'")
WORKSPACE = re.compile(r'^/github/workspace(?:/|$)')
ROOT = '.'
RUN_URL = re.compile(r'(?:github\.com/([^/\s]+/[^/\s]+))?'
                     r'/actions/runs/(\d+)(?:/job/(\d+))?')

INIT_CAS = re.compile(r'INIT : CREATE_AND_SELECT_WORKSPACE : (\S+) : '
                      r'engine=(\S+) : create_and_select_workspace=(\w+)')
API_OPEN = re.compile(r'Starting new HTTPS connection .*?: (\S+)')
API_DONE = re.compile(r'"(GET|POST|PUT|DELETE) (\S+) HTTP/[\d.]+"')
MANIFEST_ID = re.compile(r'work-manifests/([0-9a-f-]{8})')

# Ordered checkpoints that bracket the phases of a run.
MARKS = [
    ('manifest', re.compile(r'LOADING : WORK_MANIFEST')),
    ('pre', re.compile(r'EXEC : HOOKS : PRE')),
    ('post', re.compile(r'EXEC : HOOKS : POST')),
    ('done', re.compile(r'Work manifest is completed')),
]

FIND_A_RUN = """\
Give me a run to profile. Either a URL, copied from your browser with the
Terrateam job open on GitHub:

  terrateam-run-profile.py https://github.com/OWNER/REPO/actions/runs/123/job/456

Or the logs, however you got them. The zip GitHub hands you from the
"Download log archive" button works as-is, no need to pick a file out of it:

  terrateam-run-profile.py logs_32825125903.zip
  terrateam-run-profile.py ./unzipped-logs/
  terrateam-run-profile.py run.log"""


def decode(raw):
    """Bytes to text. GitHub writes UTF-8, but honour a BOM if one is there."""
    for bom, enc in ((codecs.BOM_UTF8, 'utf-8-sig'),
                     (codecs.BOM_UTF32_LE, 'utf-32'), (codecs.BOM_UTF32_BE, 'utf-32'),
                     (codecs.BOM_UTF16_LE, 'utf-16'), (codecs.BOM_UTF16_BE, 'utf-16')):
        if raw.startswith(bom):
            return raw.decode(enc, 'replace')
    return raw.decode('utf-8', 'replace')


def fetch_log(run, repo, job=None):
    """Fetch a run log with the gh CLI. Returns the log text.

    A job id narrows it to that job. Without one, a run with batch_runs
    returns every job at once, which mixes their phases and dirspaces.
    """
    cmd = ['gh', 'run', 'view', run, '--log']
    if job:
        cmd += ['--job', job]
    if repo:
        cmd += ['--repo', repo]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, errors='replace')
    except FileNotFoundError:
        sys.exit('The gh CLI is not installed, so the run cannot be fetched.\n'
                 'Install it from https://cli.github.com, or save the log yourself:\n'
                 '  gh run view %s --log > run.log' % run)
    if proc.returncode != 0:
        err = proc.stderr.strip()
        if 'HTTP 410' in err:
            sys.exit('Run %s no longer has logs. GitHub deletes workflow logs after\n'
                     'its retention window, so this run is too old to profile.\n'
                     'Pick a more recent run.' % run)
        if 'HTTP 404' in err:
            what = ('Run %s, or job %s within it, was not found.' % (run, job)
                    if job else 'Run %s was not found.' % run)
            sys.exit('%s Check the id, and pass\n--repo OWNER/REPO if you are not '
                     'inside that repository.\n\n%s' % (what, err))
        sys.exit('gh could not fetch run %s:\n%s' % (run, err))
    return proc.stdout


def read_input(target, repo):
    """Resolve the argument to log text: a URL, a zip, a directory, or a file."""
    if target is None:
        if sys.stdin.isatty():
            sys.exit(FIND_A_RUN)
        return sys.stdin.read()
    m = RUN_URL.search(target)
    if m:
        # A pasted URL names its own repository; --repo still wins if given.
        return fetch_log(m.group(2), repo or m.group(1), m.group(3))
    if target.isdigit():
        return fetch_log(target, repo)
    if not os.path.exists(target):
        sys.exit('%r is not a log file, a logs zip, or a run URL.\n\n%s'
                 % (target, FIND_A_RUN))
    if zipfile.is_zipfile(target):
        # GitHub's log archive: one .txt per job, plus one per step in a
        # per-job folder. Read them all; the parser sorts by dirspace and time.
        with zipfile.ZipFile(target) as z:
            txt = [n for n in z.namelist() if n.lower().endswith('.txt')]
            if not txt:
                sys.exit('%r has no .txt log files in it.' % target)
            # Root entries are the whole job log; the per-job folder repeats it
            # step by step. Prefer the root, and fall back if there is none.
            names = [n for n in txt if '/' not in n.strip('/')] or txt
            return '\n'.join(decode(z.read(n)) for n in names)
    if os.path.isdir(target):
        def read_txt(paths):
            out = []
            for path in sorted(paths):
                with open(path, 'rb') as f:
                    out.append(decode(f.read()))
            return out
        top = [os.path.join(target, n) for n in os.listdir(target)
               if n.lower().endswith('.txt') and os.path.isfile(os.path.join(target, n))]
        if top:
            parts = read_txt(top)            # same layout as the zip: root wins
        else:
            parts = read_txt(os.path.join(r, n)
                             for r, _, fs in os.walk(target) for n in fs
                             if n.lower().endswith('.txt'))
        if not parts:
            sys.exit('%r contains no .txt log files.' % target)
        return '\n'.join(parts)
    with open(target, 'rb') as f:
        return decode(f.read())


def parse_ts(s):
    return datetime.strptime(s[:26].ljust(26, '0') + '+0000',
                             '%Y-%m-%dT%H:%M:%S.%f%z').astimezone(timezone.utc)


def rel(path):
    return WORKSPACE.sub('', path).rstrip('/') or '.'


def label(blob):
    t = STEP_TYPE.search(blob)
    t = t.group(1) if t else 'unknown'
    if t == 'env':
        n = STEP_NAME.search(blob)
        return 'env(%s)' % n.group(1) if n else 'env'
    if t == 'run':
        c = STEP_CMD.search(blob)
        if c:
            argv = [a.strip().strip("'\"") for a in c.group(1).split(',')]
            argv = [a for a in argv if a][:2]
            return 'run(%s)' % ' '.join(argv)
    return t


class Run:
    """Everything the log tells us about one Terrateam operation."""

    def __init__(self):
        self.stats = collections.Counter()
        self.events = []          # (ts, dirspace, step_label_or_None)
        self.first = self.last = None
        self.marks = {}           # checkpoint name -> first timestamp
        self.changes = {}         # dirspace -> has_changes bool
        self.cas = {}             # dirspace -> create_and_select_workspace bool
        self.engines = set()
        self.api = []             # (seconds, method, path)
        self.clock = []           # every timestamped line, in file order
        self.activity = collections.defaultdict(list)  # dirspace -> timestamps
        self.manifest = None
        self.saw = set()          # feature markers seen, e.g. 'infracost'

    def note_time(self, ts):
        if self.first is None or ts < self.first:
            self.first = ts
        if self.last is None or ts > self.last:
            self.last = ts

    def feed(self, lines):
        pending_api = None
        for line in lines:
            self.stats['lines'] += 1
            m = TS.search(line)
            if not m:
                continue
            self.stats['timestamped'] += 1
            ts = parse_ts(m.group(1))
            self.note_time(ts)
            self.clock.append(ts)
            rest = ANSI.sub('', line[m.end():])

            for name, pat in MARKS:
                if pat.search(rest) and name not in self.marks:
                    self.marks[name] = ts

            if self.manifest is None:
                mi = MANIFEST_ID.search(rest)
                if mi:
                    self.manifest = mi.group(1)
            if 'INFRACOST' in rest:
                self.saw.add('cost estimation (infracost)')
            if 'CHECKOV' in rest:
                self.saw.add('checkov')
            if 'CONFTEST' in rest:
                self.saw.add('conftest')

            # Terrateam API round trips: connection opened, then response logged.
            if API_OPEN.search(rest):
                pending_api = ts
            else:
                d = API_DONE.search(rest)
                if d and pending_api is not None:
                    path = re.sub(r'/[0-9a-f-]{16,}', '/{id}', d.group(2)).split('?')[0]
                    self.api.append(((ts - pending_api).total_seconds(),
                                     d.group(1), path))
                    pending_api = None

            c = INIT_CAS.search(rest)
            if c:
                self.cas[rel(c.group(1))] = c.group(3) == 'True'
                self.engines.add(c.group(2))

            r = RESULTS.search(rest)
            if r:
                self.changes[rel(r.group(1))] = r.group(3) == 'True'
                self.stats['PLAN/APPLY : RESULTS'] += 1
                self.events.append((ts, rel(r.group(1)), None))
                self.activity[rel(r.group(1))].append(ts)
                continue

            s = STEP.search(rest)
            if s:
                self.stats['STEP : RUN'] += 1
                self.events.append((ts, rel(s.group(1)), label(s.group(2))))
                self.activity[rel(s.group(1))].append(ts)
                continue
            f = STEP_FAIL.search(rest)
            if f:
                # A failed step logs FAIL after it ran, and twice on the
                # exception path. It ends a step, it never starts one.
                self.stats['STEP : FAIL'] += 1
                self.events.append((ts, rel(f.group(1)), None))
                self.activity[rel(f.group(1))].append(ts)
                continue
            for name, pat in (('cwd=<dir>', CWD), ('EXEC : DIR', EXEC_DIR)):
                m2 = pat.search(rest)
                if m2:
                    self.stats[name] += 1
                    self.events.append((ts, rel(m2.group(1)), None))
                    self.activity[rel(m2.group(1))].append(ts)
                    break

    def steps(self):
        """(seconds, dirspace, label, quality) for every step.

        quality is how the end time was established:

        'exact'  Another step started on this dirspace afterwards. Steps within
                 one directory run back to back, so the gap IS the duration.
                 Hook steps at the repository root are also exact: hooks run
                 serially with nothing else in flight, so the very next
                 timestamped line in the log ends them.
        'min'    This was the last step for the directory. There is no end
                 marker, only later output attributable to it, so the number is
                 a lower bound and is printed with >=.
        None     Last step, and nothing further mentions the directory. The end
                 is unknown and is NOT invented.
        """
        clock = sorted(self.clock)
        starts = collections.defaultdict(list)
        for ts, d, step in self.events:
            if step is not None:
                starts[d].append((ts, step))
        out = []
        for d, evs in starts.items():
            evs.sort(key=lambda e: e[0])
            acts = sorted(self.activity[d])
            if d == ROOT:
                out.extend(self._root_steps(evs))
                continue
            for i, (ts, step) in enumerate(evs):
                if i + 1 < len(evs):
                    out.append(((evs[i + 1][0] - ts).total_seconds(), d, step, 'exact'))
                else:
                    later = acts[-1] if acts and acts[-1] > ts else None
                    if later is not None:
                        out.append(((later - ts).total_seconds(), d, step, 'min'))
                    else:
                        out.append((0.0, d, step, None))
        return out

    def _root_steps(self, evs):
        """Hook steps run at the repository root, serially, in two blocks that
        sit either side of the dirspace phase. Within a block one hook ends when
        the next begins: exact. The last hook of a block has no successor, so it
        is bounded above by the end of the block, and reported as 'max'."""
        first_dir = min((t for t, d, st in self.events
                         if st is not None and d != ROOT), default=None)
        done = self.marks.get('done') or self.last
        pre = [e for e in evs if first_dir is not None and e[0] < first_dir]
        post = [e for e in evs if e not in pre]
        out = []
        for block, block_end in ((pre, first_dir or done), (post, done)):
            for i, (ts, step) in enumerate(block):
                if i + 1 < len(block):
                    out.append(((block[i + 1][0] - ts).total_seconds(),
                                ROOT, step, 'exact'))
                elif block_end is not None and block_end > ts:
                    out.append(((block_end - ts).total_seconds(),
                                ROOT, step, 'max'))
                else:
                    out.append((0.0, ROOT, step, None))
        return out

    def phases(self):
        """Named spans across the whole job, in order, that actually resolved."""
        first_step = None
        for ts, d, step in sorted(self.events, key=lambda e: e[0]):
            # Hook steps run at the repository root; the dirspace phase starts
            # at the first step inside an actual directory.
            if step is not None and d != ROOT:
                first_step = ts
                break
        pts = [
            ('runner startup, before Terrateam', self.first, self.marks.get('manifest')),
            ('work manifest + repo config', self.marks.get('manifest'), self.marks.get('pre')),
            ('pre hooks', self.marks.get('pre'), first_step),
            ('dirspace steps', first_step, self.marks.get('post')),
            ('post hooks', self.marks.get('post'), self.marks.get('done')),
            ('teardown after completion', self.marks.get('done'), self.last),
        ]
        out = []
        for name, a, b in pts:
            if a is not None and b is not None and (b - a).total_seconds() > 0:
                out.append((name, (b - a).total_seconds()))
        return out


def bar(frac, width=18):
    filled = int(round(frac * width))
    return '#' * filled + '.' * (width - filled)


def table(title, rows, total, extra_header=''):
    if not rows:
        return
    print('\n%s' % title)
    print('-' * max(len(title), 34))
    w = max(len(str(r[0])) for r in rows)
    for name, secs, note in rows:
        share = secs / total if total else 0
        print('  %-*s  %8.1fs  %5.1f%%  %-18s %s'
              % (w, name, secs, 100 * share, bar(share), note))


def nothing_to_time(run):
    counts = '\n'.join('    %-22s %8d' % (k, run.stats[k])
                       for k in ('lines', 'timestamped', 'STEP : RUN',
                                 'cwd=<dir>', 'EXEC : DIR', 'PLAN/APPLY : RESULTS'))
    sys.exit(
        'Nothing to time in this input.\n\n'
        'What I found:\n%s\n\n'
        'A Terrateam plan or apply writes one "STEP : RUN" line per step, per\n'
        'directory. There are none here, so this run executed no workflow steps.\n\n'
        'The usual cause is that this is a tree-builder, config-builder, or indexer\n'
        'run. Terrateam dispatches those as their own GitHub Actions runs, and they\n'
        'have nothing to profile. Open the pull request, find the run that posted the\n'
        'plan, and profile that one instead.\n\n'
        'If this IS the plan or apply run, that is a bug in this script. Send the\n'
        'output above to support@terrateam.io or the Terrateam Community Slack.'
        % counts)


def report(run, top):
    steps = run.steps()
    if not steps:
        nothing_to_time(run)

    wall = (run.last - run.first).total_seconds()
    step_total = sum(s[0] for s in steps)
    dirs = sorted({d for _, d, _, _ in steps if d != ROOT})

    head = 'Terrateam run'
    if run.manifest:
        head += ' %s' % run.manifest
    head += '  |  %d dirspace%s' % (len(dirs), '' if len(dirs) == 1 else 's')
    if run.engines:
        head += '  |  %s' % ', '.join(sorted(run.engines))
    print(head)
    print('=' * max(len(head), 34))
    phases = run.phases()
    span = dict(phases).get('dirspace steps', 0)
    dir_time = sum(s[0] for s in steps if s[1] != ROOT)
    n_min = sum(1 for s in steps if s[3] == 'min')
    n_maxq = sum(1 for s in steps if s[3] == 'max')
    n_unk = sum(1 for s in steps if s[3] is None)
    print('  wall clock            %8.1fs' % wall)
    # Concurrent directories mean this legitimately exceeds wall clock, so it
    # is not expressed as a percentage of it.
    print('  step time, summed     %8.1fs  across all directories' % step_total)
    if n_min or n_unk or n_maxq:
        bits = []
        if n_min:
            bits.append('%d at least (>)' % n_min)
        n_max = sum(1 for s in steps if s[3] == 'max')
        if n_max:
            bits.append('%d at most (<)' % n_max)
        if n_unk:
            bits.append('%d with an unknown end (?)'
                        % n_unk)
        print('  measurement           %s' % '; '.join(bits))
    if span:
        print('  dirspace concurrency  %8.1fx  (%.1fs of step time in a %.1fs window)'
              % (dir_time / span, dir_time, span))
    accounted = sum(p[1] for p in phases)
    rows = [(n, s, '') for n, s in phases]
    if wall - accounted > 0.5:
        rows.append(('unaccounted', wall - accounted, 'gaps between markers'))
    table('WHERE THE WALL CLOCK WENT', rows, wall)

    by_step = collections.Counter()
    n_step = collections.Counter()
    inexact = collections.Counter()
    for secs, _, step, q in steps:
        by_step[step] += secs
        n_step[step] += 1
        if q != 'exact':
            inexact[step] += 1
    table('STEP TIME BY TYPE',
          [(k, v, 'x%d%s' % (n_step[k], '  (%d not exact)' % inexact[k]
                             if inexact[k] else ''))
           for k, v in by_step.most_common()], step_total)

    by_dir = collections.Counter()
    dir_inexact = collections.Counter()
    for secs, d, _, q in steps:
        by_dir[d] += secs
        if q != 'exact':
            dir_inexact[d] += 1
    table('STEP TIME BY DIRSPACE',
          [(d if d != ROOT else '. (hooks, repo root)', v,
            ' '.join(filter(None, [
                {True: 'has changes', False: 'NO CHANGES', None: ''}[run.changes.get(d)],
                '(%d not exact)' % dir_inexact[d] if dir_inexact[d] else ''])))
           for d, v in by_dir.most_common()], step_total)

    if run.api:
        api_total = sum(a[0] for a in run.api)
        agg = collections.Counter()
        cnt = collections.Counter()
        for secs, method, path in run.api:
            key = '%s %s' % (method, path)
            agg[key] += secs
            cnt[key] += 1
        table('TERRATEAM API TIME  (%.1fs, %.1f%% of wall clock)'
              % (api_total, 100 * api_total / wall if wall else 0),
              [(k, v, 'x%d' % cnt[k]) for k, v in agg.most_common()], api_total)

    print('\nSLOWEST INDIVIDUAL STEPS')
    print('-' * 34)
    for secs, d, step, q in sorted(steps, key=lambda s: s[0],
                                   reverse=True)[:top]:
        mark = {'exact': ' ', 'min': '>', 'max': '<', None: '?'}[q]
        print('  %s%7.1fs  %-26s %s%s'
              % (mark, secs, step, d,
                 {'exact': '', 'min': '  (at least)', 'max': '  (at most)',
                  None: '  (end unknown)'}[q]))

    print('\nSIGNALS')
    print('-' * 34)
    signals = []
    on = [d for d, v in run.cas.items() if v]
    if on:
        signals.append(
            'create_and_select_workspace is on for %d of %d dirspaces. If every '
            'directory uses the default workspace, setting it to false removes one '
            'tool invocation per dirspace.' % (len(on), len(run.cas)))
    nochange = [d for d in dirs if run.changes.get(d) is False]
    if nochange:
        signals.append(
            '%d of %d dirspaces planned with no changes (%s). Narrowing '
            'file_patterns keeps them out of the run entirely.'
            % (len(nochange), len(dirs), ', '.join(sorted(nochange)[:3])))
    validate = [s for s in by_step if 'validate' in s]
    if validate:
        signals.append(
            'A validate step is running (%s), %.1fs total. plan surfaces the same '
            'errors, so this is usually removable.'
            % (validate[0], sum(by_step[v] for v in validate)))
    if run.api and wall and sum(a[0] for a in run.api) / wall > 0.15:
        signals.append(
            'Terrateam API calls are %.0f%% of the run. That is latency to the '
            'Terrateam server, not your Terraform.'
            % (100 * sum(a[0] for a in run.api) / wall))
    startup = dict(phases).get('runner startup, before Terrateam', 0)
    if startup > 0.2 * wall and startup > 10:
        signals.append(
            'Runner startup is %.0fs before Terrateam does anything, %.0f%% of the '
            'run. That is queue, action image build, and checkout.'
            % (startup, 100 * startup / wall))
    for feat in sorted(run.saw):
        signals.append('%s is enabled in this run.' % feat)
    if not signals:
        signals.append('Nothing configuration-level stands out. The time is in the '
                       'steps above.')
    for s in signals:
        for i, chunk in enumerate(textwrap.wrap(s, 72)):
            print('  %s %s' % ('*' if i == 0 else ' ', chunk))


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('run', nargs='?', metavar='URL-OR-LOG',
                    help='a GitHub Actions run or job URL, a logs zip, a log '
                         'directory, or a log file. stdin also works.')
    ap.add_argument('-R', '--repo', metavar='OWNER/REPO',
                    help='repository to fetch the run from, for a run id or URL')
    ap.add_argument('-n', '--top', type=int, default=15,
                    help='how many individual steps to list (default 15)')
    args = ap.parse_args()

    run = Run()
    run.feed(read_input(args.run, args.repo).splitlines())
    if not run.events:
        nothing_to_time(run)
    report(run, args.top)


if __name__ == '__main__':
    main()

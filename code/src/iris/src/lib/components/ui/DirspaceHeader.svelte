<script lang="ts">
  import type { ResourceSummary } from '../../types/stepOutput';

  // Collapsed dirspace header button: status dot, dir/workspace label, the
  // optional resource-summary line, step count + suffix, chevron. Shared by
  // the All Steps and Raw Steps tabs; the container div and expanded body
  // stay with each tab because they differ.

  export let dir: string;
  export let workspace: string;
  export let success: boolean | undefined = undefined;
  export let stepCount: number;
  export let suffix: string = '';
  export let resourceSummary: ResourceSummary | null = null;
  export let expanded: boolean = false;
  export let onToggle: () => void;

  // Four fixed slots in the runner's order, paired with the present-tense
  // word each slot renders as (the data keys stay past tense — payload
  // contract). An unreported count renders `-`, so a partial summary still
  // fills the line, and the counts are joined with `, ` (the backend
  // `count_str` and `describe` conventions). No plan step, no payload key, or
  // all four slots unreported hides the line.
  function summaryLine(rs: ResourceSummary | null): string {
    if (!rs) return '';
    const slots: Array<[keyof ResourceSummary, string]> = [
      ['created', 'create'],
      ['updated', 'update'],
      ['replaced', 'replace'],
      ['deleted', 'delete'],
    ];
    if (slots.every(([slot]) => rs[slot] == null)) return '';
    return slots.map(([slot, label]) => `${rs[slot] ?? '-'} ${label}`).join(', ');
  }

  $: line = summaryLine(resourceSummary);
</script>

<button
  on:click={onToggle}
  class="w-full flex items-center justify-between p-4 text-left hover:bg-[var(--sg-bg-2)] focus:outline-none focus:ring-2 focus:ring-[var(--sg-accent)] focus:ring-inset"
>
  <div class="flex items-center space-x-3 flex-1 min-w-0">
    <div class="flex-shrink-0">
      {#if success === true}
        <div class="w-3 h-3 rounded-full bg-[var(--sg-success)]"></div>
      {:else if success === false}
        <div class="w-3 h-3 rounded-full bg-[var(--sg-error)]"></div>
      {:else}
        <div class="w-3 h-3 rounded-full bg-[var(--sg-bg-2)]"></div>
      {/if}
    </div>
    <div class="flex-1 min-w-0">
      <div class="font-medium text-[var(--sg-text)] truncate">{dir}</div>
      <div class="text-sm text-[var(--sg-text-dim)] truncate">Workspace: {workspace}</div>
      {#if line}
        <div class="text-sm text-[var(--sg-text-muted)]">{line}</div>
      {/if}
    </div>
  </div>
  <div class="flex items-center space-x-2 flex-shrink-0">
    <span class="text-xs sm:text-sm text-[var(--sg-text-dim)]">
      <span class="hidden sm:inline">{stepCount} step{stepCount !== 1 ? 's' : ''}{suffix}</span>
      <span class="sm:hidden">{stepCount} {stepCount === 1 ? 'step' : 'steps'}</span>
    </span>
    <svg class="w-5 h-5 text-[var(--sg-text-dim)] transform transition-transform {expanded ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
    </svg>
  </div>
</button>

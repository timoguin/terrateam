.PHONY: all release debug clean clean_all_site_files docs

site_files = $(notdir $(wildcard $(SRC_DIR)/*.html) \
	$(wildcard $(SRC_DIR)/*.css) \
	$(wildcard $(SRC_DIR)/*.png) \
	$(wildcard $(SRC_DIR)/*.json) \
	$(wildcard $(SRC_DIR)/*.svg)) \
	index.html

all: release

release: $(site_files)

debug: $(site_files)

profile: $(site_files)

docs:

clean: clean_all_files

clean_all_files:
	-rm $(site_files)

index.html: $(SRC_DIR)/index.html.tmpl
	./"$<" > "$@"

%.html: $(SRC_DIR)/%.html
	cp $< $@

%.css: $(SRC_DIR)/%.css
	cp $< $@

%.png: $(SRC_DIR)/%.png
	cp $< $@

%.svg: $(SRC_DIR)/%.svg
	cp $< $@

%.json: $(SRC_DIR)/%.json
	cp $< $@

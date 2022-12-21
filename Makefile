BROWSERIFY = ./node_modules/browserify/bin/cmd.js
MINIFY = ./node_modules/.bin/minify
freak_CURRENT = node ./bin/freak.js
FLAGS =
INSTALL_MESSAGE = "Dependencies are not yet installed. Run npm i"
BUILD_DEPS = $(BROWSERIFY) $(MINIFY) ./node_modules/freaklang/bin/freak.js

vpath % src

ifdef verbose
	FLAGS = --verbose
endif

ifdef current
	freak = $(freak_CURRENT)
else
	freak = ./node_modules/freaklang/bin/freak.js
endif

CORE = expander runtime sequence string ast reader compiler analyzer
core: $(CORE) writer escodegen
escodegen: escodegen-writer escodegen-generator
node: core freak node-engine repl
browser: node core browser-engine dist/freak.min.js
all: browser

test: core node recompile
	$(freak_CURRENT) ./test/test.freak $(FLAGS)

$(BUILD_DEPS):
	@echo $(INSTALL_MESSAGE)
	@exit 1

clean:
	rm -rf engine
	rm -rf backend
	rm -rf dist
	rm -f *.js

%.js: %.freak $(freak)
	@mkdir -p $(dir $@)
	$(freak) --source-uri freak/$(subst .js,.freak,$@) < $< > $@

RECOMPILE = backend/escodegen/writer backend/escodegen/generator backend/javascript/writer engine/node engine/browser $(CORE)
recompile: node browser-engine
	$(info Recompiling with current version:)
	@$(foreach file,$(RECOMPILE),\
		echo "	$(file)" && \
		$(freak_CURRENT) --source-uri freak/$(file).freak < src/$(file).freak > $(file).js~ && \
		mv $(file).js~ $(file).js &&) echo "...done"

repl: repl.js
reader: reader.js
compiler: compiler.js
runtime: runtime.js
sequence: sequence.js
string: string.js
ast: ast.js
analyzer: analyzer.js
expander: expander.js
freak: freak.js
writer: backend/javascript/writer.js
escodegen-writer: backend/escodegen/writer.js
escodegen-generator: backend/escodegen/generator.js
node-engine: ./engine/node.js
browser-engine: ./engine/browser.js

dist/freak.js: engine/browser.js $(freak) $(BROWSERIFY) browserify.freak core recompile
	@mkdir -p dist
	$(freak_CURRENT) browserify.freak > dist/freak.js

dist/freak.min.js: dist/freak.js $(MINIFY)
	@mkdir -p dist
	$(MINIFY) dist/freak.js > dist/freak.min.js
	@cp node_modules/.bin/freak bin/freak

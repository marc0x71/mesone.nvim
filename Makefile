.PHONY: test 

test: unit integration 

unit: build 
	echo "----UNIT----"
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory test/unit/ { minimal_init = './scripts/minimal_init.vim' }"

integration: build 
	echo "----INTEGRATION----"
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory test/integration/ { minimal_init = './scripts/minimal_init.vim' }"

build: 
	$(MAKE) -C test build

clean: 
	$(MAKE) -C test clean

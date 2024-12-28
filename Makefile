.PHONY: test 

INIT = test/minimal_init.vim
PLENARY_OPTS = {minimal_init='${INIT}', sequential=true}

test: unit integration 

unit: build 
	echo "----UNIT----"
	nvim --headless -c "PlenaryBustedDirectory test/unit ${PLENARY_OPTS}"

integration: build 
	echo "----INTEGRATION----"
	nvim --headless -c "PlenaryBustedDirectory test/integration ${PLENARY_OPTS}"

build: 
	$(MAKE) -C test build

clean: 
	$(MAKE) -C test clean

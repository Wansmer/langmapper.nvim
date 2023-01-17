test:
	nvim --headless -u tests/minimal.lua -c "PlenaryBustedDirectory tests {minimal_init = 'tests/minimal.lua'}"

test-ctrl:
	nvim --headless -u tests/minimal.lua -c "PlenaryBustedDirectory tests/ctrl {minimal_init = 'tests/minimal.lua'}"

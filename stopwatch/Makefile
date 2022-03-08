PROJ = stopwatch
BUILD_FOLDER = build

all: ${BUILD_FOLDER}/$(PROJ).rpt ${BUILD_FOLDER}/$(PROJ).bin

${BUILD_FOLDER}/$(PROJ).json: $(PROJ).v
	@mkdir -p ${BUILD_FOLDER}
	yosys -ql ${BUILD_FOLDER}/$(PROJ).yslog -p 'synth_ice40 -top top -json $@' $<

${BUILD_FOLDER}/$(PROJ).asc: ${BUILD_FOLDER}/$(PROJ).json icebreaker.pcf
	nextpnr-ice40 -ql $(PROJ).nplog --up5k --package sg48 --freq 12 --asc $@ --pcf icebreaker.pcf --json $<

${BUILD_FOLDER}/$(PROJ).bin: ${BUILD_FOLDER}/$(PROJ).asc
	icepack $< $@

${BUILD_FOLDER}/$(PROJ).rpt: ${BUILD_FOLDER}/$(PROJ).asc
	icetime -d up5k -c 12 -mtr $@ $<

${BUILD_FOLDER}/$(PROJ)_tb: ${BUILD_FOLDER}/$(PROJ)_tb.v $(PROJ).v
	iverilog -o $@ $^

${BUILD_FOLDER}/$(PROJ)_tb.vcd: ${BUILD_FOLDER}/$(PROJ)_tb
	vvp -N $< +vcd=$@

${BUILD_FOLDER}/$(PROJ)_syn.v: ${BUILD_FOLDER}/$(PROJ).json
	yosys -p 'read_json $^; write_verilog $@'

${BUILD_FOLDER}/$(PROJ)_syntb: ${BUILD_FOLDER}/$(PROJ)_tb.v $(PROJ)_syn.v
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

${BUILD_FOLDER}/$(PROJ)_syntb.vcd: ${BUILD_FOLDER}/$(PROJ)_syntb
	vvp -N $< +vcd=$@

prog:${BUILD_FOLDER}/$(PROJ).bin
	iceprog $<

sudo-prog: ${BUILD_FOLDER}/$(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -rf ${BUILD_FOLDER}/

.SECONDARY:
.PHONY: all prog clean

all : output time space

output :
	@echo ""
	@echo "Step 1. Output comparison"
	@echo ""
	@./TestAll.sh | tee diffs.txt 
	@echo ""

time :
	@echo "Step 2. Time comparison"
	@echo ""
	@./TestAll.sh performance | tee diffs-performance.txt | grep -e "^====" -e " real .* user .* sys" 
	@echo ""

space :
	@echo "Step 3. Space comparison"
	@echo ""
	@./TestAll.sh performance | tee diffs-performance.txt | grep -e "^====" -e "Used a total" 
	@echo ""
	@echo "Done."
	@echo ""

clean :
	/bin/rm -f diffs.txt diffs-performance.txt */*-oldoutput */*-newoutput

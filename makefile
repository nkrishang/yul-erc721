.PHONY: benchmark

benchmark:
	@forge test --mc Benchmark > test_output.txt
	@echo "| Test | YUL | SOLADY | SOLMATE |" > benchmark.md
	@echo "|------|-----|--------|---------|" >> benchmark.md
	@gawk '/\[PASS\]/ { \
		match($$2, /test_(.+)_(.+)\(\)/, arr); \
		test = arr[1]; \
		type = arr[2]; \
		gsub(/\(|\)/, "", $$NF); \
		gas = $$NF; \
		if (type == "yul") yul[test] = gas; \
		else if (type == "solady") solady[test] = gas; \
		else if (type == "solmate") solmate[test] = gas; \
		tests[test] = 1; \
	} \
	END { \
		for (test in tests) { \
			printf "| %s | %s | %s | %s |\n", \
				test, \
				(yul[test] ? yul[test] : "-"), \
				(solady[test] ? solady[test] : "-"), \
				(solmate[test] ? solmate[test] : "-"); \
		} \
	}' test_output.txt | sort >> benchmark.md
	@rm test_output.txt
	@echo "Benchmark results have been written to benchmark.md"

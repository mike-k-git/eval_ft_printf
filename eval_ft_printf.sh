#!/bin/bash

# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# settings
BUFFER_SIZES=(1 42 10000000)
USE_VALGRIND=true
LOG="eval.log"
MAIN_EMPTY="main_empty.c"
GNL_EXEC="a.out"
ALLOWED_FUNCTIONS=("read" "malloc" "free" "main")

# paths
SRC_DIR=".."
GNL_SRC="$SRC_DIR/get_next_line.c"
GNL_UTILS="$SRC_DIR/get_next_line_utils.c"
GNL_HEADER="$SRC_DIR/get_next_line.h"
BONUS_SRC="$SRC_DIR/get_next_line_bonus.c"
BONUS_UTILS="$SRC_DIR/get_next_line_utils_bonus.c"
BONUS_HEADER="$SRC_DIR/get_next_line_bonus.h"
MANDATORY_MAIN="mandatory.c"
BONUS_MAIN="bonus.c"
MANDATORY_FILES=("$GNL_SRC" "$GNL_UTILS" "$GNL_HEADER" "$MANDATORY_MAIN")
BONUS_FILES=("$BONUS_SRC" "$BONUS_UTILS" "$BONUS_HEADER" "$MANDATORY_MAIN")

cleanup() {
	rm -f test_*.txt output_*.txt valgrind*.log a.out
}
trap cleanup EXIT INT

print_ok() { echo -e "[${1}] ${GREEN}OK${NC}"; }
print_ko() { echo -e "[${1}] ${RED}KO${NC}!"; }
print_warn() { echo -e "${YELLOW}$1${NC}"; }

check_valgrind() {
	local log_file=$1
	if grep -qE "definitely lost: [^0]|indirectly lost: [^0]|ERROR SUMMARY: [^0]*[1-9]" "$log_file"; then
		print_ko "Valgrind"
		cat "$log_file"
	else
		print_ok "Valgrind"
	fi
	rm -f "$log_file"
}

run_test() {
	local test_name=$1
	local test_content=$2
	local expected_output=$3

	local test_file="test_${test_name}.txt"
	local output_file="output_${test_name}.txt"

	printf "%s" "$test_content" >"$test_file"

	if $USE_VALGRIND; then
		valgrind --leak-check=full --error-exitcode=1 ./$GNL_EXEC "$test_file" >"$output_file" 2>./valgrind.log
		if [ $? -ne 0 ]; then
			print_ko "Valgrind"
			cat ./valgrind.log
		else
			print_ok "Valgrind"
		fi
		rm ./valgrind.log
	else
		./$GNL_EXEC "$test_file" >"$output_file"
	fi

	actual_output=$(cat "$output_file")
	if diff -q "$output_file" <(printf "%s" "$expected_output") >/dev/null; then
		print_ok "$test_name" | tee -a "$LOG"
	else
		print_ko "$test_name"
		{
			echo [KO] "$test_name"
			echo "Expected:"
			printf "%s" "$expected_output" | od -c
			echo "Got:"
			cat "$output_file" | od -c
		} >>"$LOG"
	fi
	rm -f "$test_file" "$output_file"
}

run_stdin_test() {
	local test_name=$1
	local test_content=$2
	local expected_output=$3
	local output_file="output_${test_name}.txt"

	if $USE_VALGRIND; then
		echo -e "$test_content" | valgrind --leak-check=full --error-exitcode=1 ./$GNL_EXEC stdin >"$output_file" 2>./valgrind_stdin.log
		if [ $? -ne 0 ]; then
			print_ko "Valgrind"
			cat ./valgrind_stdin.log >>"$LOG"
		else
			print_ok "Valgrind"
		fi
		rm ./valgrind_stdin.log
	else
		echo -e "$test_content" | ./$GNL_EXEC stdin >"$output_file"
	fi
	actual_output=$(cat "$output_file")
	if diff -q <(printf "%s" "$expected_output") <(printf "%s" "$actual_output") >/dev/null; then
		print_ok "$test_name"
		echo [OK] "$test_name" >>"$LOG"
	else
		print_ko "$test_name" | tee -a "$LOG"
		{
			echo [KO] "$test_name"
			echo "Expected:"
			printf "%s" "$expected_output" | od -c
			echo "Got:"
			printf "%s" "$actual_output" | od -c
		} >>"$LOG"
	fi
}

run_neg_fd_test() {
	if $USE_VALGRIND; then
		output=$(valgrind --leak-check=full --error-exitcode=1 ./$GNL_EXEC neg_fd 2>./valgrind_neg_fd.log)
	else
		output=$(./$GNL_EXEC neg_fd)
	fi
	if [ -z "$output" ]; then
		print_ok "Negative FD"
	else
		print_ko "Negative FD"
		echo "Expected empty output but got:"
		echo "$output"
	fi

	if $USE_VALGRIND; then
		check_valgrind valgrind_neg_fd.log
	fi
}

run_too_big_fd_test() {
	if $USE_VALGRIND; then
		output=$(valgrind --leak-check=full --error-exitcode=1 ./$GNL_EXEC too_big_fd 2>./valgrind_too_big_fd.log)
	else
		output=$(./$GNL_EXEC too_big_fd)
	fi
	if [ -z "$output" ]; then
		print_ok "Too big FD"
	else
		print_ko "Too big FD"
		echo "Expected empty output but got:"
		echo "$output"
	fi

	if $USE_VALGRIND; then
		check_valgrind valgrind_too_big_fd.log
	fi
}

run_closed_fd_test() {
	if $USE_VALGRIND; then
		output=$(valgrind --leak-check=full --error-exitcode=1 ./$GNL_EXEC closed_fd 2>./valgrind_closed_fd.log)
	else
		output=$(./$GNL_EXEC closed_fd)
	fi
	if [ -z "$output" ]; then
		print_ok "Closed FD"
	else
		print_ko "Closed FD"
		echo "Expected empty output but got:"
		echo "$output"
	fi

	if $USE_VALGRIND; then
		check_valgrind valgrind_closed_fd.log
	fi
}

if [ -f "$LOG" ]; then
	rm "$LOG"
fi

check_files() {
	local files=("$@")

	echo -n "Checking if files exist... "
	for f in "${files[@]}"; do
		if [ -f "$f" ]; then
			echo "File '$f' is found." >>"$LOG"
		else
			echo "File '$f' does not exist." >>"$LOG"
			echo -e "${RED}KO.${NC}"
			echo -e "${YELLOW}Evaluation complete. See $LOG for details.${NC}"
			exit 1
		fi
	done
	echo -e "${GREEN}OK.${NC}"
}

check_norminette() {
	local files=("$@")

	echo -n "Checking with norminette... "
	for f in "${files[@]}"; do
		if [ "$f" == "$MANDATORY_MAIN" ] || [ "$f" == "$BONUS_MAIN" ]; then
			continue
		fi
		output=$(norminette -R CheckForbiddenSourceHeader "$f")
		echo "$output" >>"$LOG"
		if echo "$output" | grep -q "Error"; then
			echo -e "${RED}KO.${NC}"
			echo -e "${YELLOW}Evaluation complete. See $LOG for details.${NC}"
			exit 1
		fi
	done
	echo -e "${GREEN}OK.${NC}"
}

check_functions() {
	local files=("$@")
	echo "int main(void) { return 0; }" >"$MAIN_EMPTY"

	echo -n "Compiling main part... "
	cc -Wall -Wextra -Werror "${files[@]}" "$MAIN_EMPTY" -o a.out 2>>"$LOG"
	rm -f "$MAIN_EMPTY"

	if [ ! -f "a.out" ]; then
		echo -e "${RED}KO.${NC}"
		echo -e "${YELLOW}Evaluation complete. See $LOG for details.${NC}"
		exit 1
	fi
	echo -e "${GREEN}OK.${NC}"

	echo -n "Checking for forbidden functions... "
	local symbols=$(nm a.out | awk '/ U / {print $2}' | sed 's/^_*//' | sed 's/^libc_start_//')

	for s in $symbols; do
		FUNC_NAME=${s%@*}
		allowed=false
		for f in "${ALLOWED_FUNCTIONS[@]}"; do
			if [[ "$FUNC_NAME" == "$f" ]]; then
				allowed=true
				break
			fi
		done
		if ! $allowed; then
			echo -e "${RED}KO.${NC}"
			echo "Forbidden function $FUNC_NAME." >>${LOG}
			echo -e "${YELLOW}Evaluation complete. See $LOG for details.${NC}"
			rm -f a.out
			exit 1
		fi
	done

	rm -f a.out
	echo -e "${GREEN}OK.${NC}"
}

clear
echo -e "${YELLOW}The evaluation is about to start.${NC}"
read -p "$(printf "${YELLOW}Do you want to evaluate the bonus part? (y/n): ${NC}")" answer
echo -e "\n${GREEN}Evaluation of the main part...${NC}"
check_files "${MANDATORY_FILES[@]}"
check_norminette "${MANDATORY_FILES[@]}"
check_functions "$GNL_SRC" "$GNL_UTILS"

for BUFFER_SIZE in "${BUFFER_SIZES[@]}"; do
	echo -e "${YELLOW}Testing get_next_line with BUFFER_SIZE=${BUFFER_SIZE}...${NC}"
	cc -Wall -Wextra -Werror -g -D BUFFER_SIZE="$BUFFER_SIZE" "$GNL_SRC" "$GNL_UTILS" "$MANDATORY_MAIN" -o "$GNL_EXEC"

	run_neg_fd_test
	run_too_big_fd_test
	run_closed_fd_test
	run_test "Empty file" "" ""
	run_test "Only new line" "\n" "\n"
	run_test "41 no new line" "$(printf '=%.0s' {1..41})" "$(printf '=%.0s' {1..41})"
	run_test "41 new line" "$(printf '=%.0s' {1..41})"$'\n' "$(printf '=%.0s' {1..41})"$'\n'
	run_test "42 no new line" "$(printf '=%.0s' {1..42})" "$(printf '=%.0s' {1..42})"
	run_test "42 new line" "$(printf '=%.0s' {1..42})"$'\n' "$(printf '=%.0s' {1..42})"$'\n'
	run_test "43 no new line" "$(printf '=%.0s' {1..43})" "$(printf '=%.0s' {1..43})"
	run_test "43 new line" "$(printf '=%.0s' {1..43})"$'\n' "$(printf '=%.0s' {1..43})"$'\n'
	run_test "Multiple new line x5" "\n\n\n\n\n" "\n\n\n\n\n"
	run_test "Multiple lines no new line" $'Line1\nLine2\nLine3' $'Line1\nLine2\nLine3'
	run_test "Multiple lines with new line" $'Line1\nLine2\nLine3\n' $'Line1\nLine2\nLine3\n'
	run_test "Alternate line new line no new line" $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5' $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5'
	run_test "Alternate line new line with new line" $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5\n' $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5\n'
	run_test "big line no new line" "$(printf '=%.0s' {1..10000})" "$(printf '=%.0s' {1..10000})"
	run_test "big line new line" "$(printf '=%.0s' {1..10000})"$'\n' "$(printf '=%.0s' {1..10000})"$'\n'
	run_stdin_test "stdin" $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5' $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5'
done

run_multi_test() {
	local test_name=$1
	shift
	local expected_output=${@: -1}
	local input_files=("${@:1:$#-1}")

	local input_filenames=()
	local output_file="output_${test_name}.txt"

	for i in "${!input_files[@]}"; do
		local file="test_${test_name}_$((i + 1)).txt"
		printf "%s" "${input_files[$i]}" >"$file"
		input_filenames+=("$file")
	done

	if $USE_VALGRIND; then
		valgrind --leak-check=full --error-exitcode=1 ./$GNL_EXEC "multi_fd" "${input_filenames[@]}" >"$output_file" 2>./valgrind.log
		if [ $? -ne 0 ]; then
			print_ko "Valgrind"
			cat ./valgrind.log
		else
			print_ok "Valgrind"
		fi
		rm ./valgrind.log
	else
		./$GNL_EXEC "multi_fd" "${input_filenames[@]}" >"$output_file"
	fi

	if diff -q "$output_file" <(printf "%s" "$expected_output") >/dev/null; then
		print_ok "$test_name" | tee -a "$LOG"
	else
		print_ko "$test_name"
		{
			echo [KO] "$test_name"
			echo "Expected:"
			printf "%s" "$expected_output" | od -c
			echo "Got:"
			cat "$output_file" | od -c
		} >>"$LOG"
	fi

	rm -f "${input_filenames[@]}" "$output_file"
}

if [[ "$answer" =~ ^[Yy]$ ]]; then
	echo -e "\n${GREEN}Evaluation of the bonus part...${NC}"
	check_files "${BONUS_FILES[@]}"
	check_norminette "${BONUS_FILES[@]}"
	check_functions "$BONUS_SRC" "$BONUS_UTILS"

	for BUFFER_SIZE in "${BUFFER_SIZES[@]}"; do
		echo -e "${YELLOW}Testing get_next_line_bonus with BUFFER_SIZE=${BUFFER_SIZE}...${NC}"
		cc -Wall -Wextra -Werror -g -D BUFFER_SIZE="$BUFFER_SIZE" "$BONUS_SRC" "$BONUS_UTILS" "$BONUS_MAIN" -o "$GNL_EXEC"

		run_neg_fd_test
		run_too_big_fd_test
		run_closed_fd_test
		run_test "Empty file" "" ""
		run_test "Only new line" "\n" "\n"
		run_test "41 no new line" "$(printf '=%.0s' {1..41})" "$(printf '=%.0s' {1..41})"
		run_test "41 new line" "$(printf '=%.0s' {1..41})"$'\n' "$(printf '=%.0s' {1..41})"$'\n'
		run_test "42 no new line" "$(printf '=%.0s' {1..42})" "$(printf '=%.0s' {1..42})"
		run_test "42 new line" "$(printf '=%.0s' {1..42})"$'\n' "$(printf '=%.0s' {1..42})"$'\n'
		run_test "43 no new line" "$(printf '=%.0s' {1..43})" "$(printf '=%.0s' {1..43})"
		run_test "43 new line" "$(printf '=%.0s' {1..43})"$'\n' "$(printf '=%.0s' {1..43})"$'\n'
		run_test "Multiple new line x5" "\n\n\n\n\n" "\n\n\n\n\n"
		run_test "Multiple lines no new line" $'Line1\nLine2\nLine3' $'Line1\nLine2\nLine3'
		run_test "Multiple lines with new line" $'Line1\nLine2\nLine3\n' $'Line1\nLine2\nLine3\n'
		run_test "Alternate line new line no new line" $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5' $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5'
		run_test "Alternate line new line with new line" $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5\n' $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5\n'
		run_test "big line no new line" "$(printf '=%.0s' {1..10000})" "$(printf '=%.0s' {1..10000})"
		run_test "big line new line" "$(printf '=%.0s' {1..10000})"$'\n' "$(printf '=%.0s' {1..10000})"$'\n'
		run_stdin_test "stdin" $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5' $'Line1\n\nLine2\n\nLine3\n\nLine4\n\nLine5'
		run_multi_test "multi_file_test" \
			$'Line1_file1\nLine2_file1\n' \
			$'Line1_file2\nLine2_file2\n' \
			$'Line1_file1\nLine1_file2\nLine2_file1\nLine2_file2\n'
	done

else
	echo -e "${YELLOW}Skipping bonus evaluation.${NC}"
fi

echo -e "${YELLOW}Evaluation complete. See $LOG for details.${NC}"

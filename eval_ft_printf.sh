#!/bin/bash

# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# settings
USE_VALGRIND=true
LOG="eval.log"
MAIN_EMPTY="main_empty.c"
EXEC="ft_printf_test"
ALLOWED_FUNCTIONS=("malloc" "free" "write" "va_start" "va_arg" "va_copy" "va_end")

# paths
SRC_DIR=".."
OBJS=$(find "$SRC_DIR" -maxdepth 2 \( -path "$SRC_DIR/eval_ft_printf" -prune \) -o -name "*.c" -print)
INCLUDES=$(find "$SRC_DIR" -maxdepth 2 \( -path "$SRC_DIR/eval_ft_printf" -prune \) -o -name "*.h" -print)
TEST_MAIN="mandatory.c"
FILES=("$TEST_MAIN" "${OBJS[@]}" "${INCLUDES[@]}")

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

if [ -f "$LOG" ]; then
	rm "$LOG"
fi

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
	local files="$@"
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
check_norminette ("${OBJS[@]}" "${INCLUDES[@]}")
check_functions "${OBJS[@]}" "${INCLUDES[@]}"

	#echo -e "${YELLOW}Testing get_next_line with BUFFER_SIZE=${BUFFER_SIZE}...${NC}"
	#cc -Wall -Wextra -Werror -g -D BUFFER_SIZE="$BUFFER_SIZE" "$GNL_SRC" "$GNL_UTILS" "$MANDATORY_MAIN" -o "$GNL_EXEC"

if [[ "$answer" =~ ^[Yy]$ ]]; then
	echo -e "\n${GREEN}Evaluation of the bonus part...${NC}"
	check_norminette "${BONUS_FILES[@]}"
	check_functions "$BONUS_SRC" "$BONUS_UTILS"

		#echo -e "${YELLOW}Testing get_next_line_bonus with BUFFER_SIZE=${BUFFER_SIZE}...${NC}"
		#cc -Wall -Wextra -Werror -g -D BUFFER_SIZE="$BUFFER_SIZE" "$BONUS_SRC" "$BONUS_UTILS" "$BONUS_MAIN" -o "$GNL_EXEC"


else
	echo -e "${YELLOW}Skipping bonus evaluation.${NC}"
fi

echo -e "${YELLOW}Evaluation complete. See $LOG for details.${NC}"

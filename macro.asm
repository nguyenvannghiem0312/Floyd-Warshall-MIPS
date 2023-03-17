.macro read_int(%int)               # Read direct an int to register
    .text
        li $v0, 5
        syscall
        move %int, $v0
.end_macro

.macro print_int(%int)              # Print integer
    .text
        li $v0, 1
        move $a0, %int
        syscall
.end_macro

.macro endl                         # Print an end-of-line chars
    li $v0 11
    li $a0 '\n'
    syscall
.end_macro

.macro space                        # Print a space chars
    li $v0 11
    li $a0 ' '
    syscall
.end_macro

.macro tab                          # Print a tab chars
    li $v0 11
    li $a0 '\t'
    syscall
.end_macro

.macro comma                        # Print a comma chars
    li $v0 11
    li $a0 ','
    syscall
.end_macro

.macro open                         # Print (
    li $v0 11
    li $a0 '('
    syscall
.end_macro

.macro close                        # Print )
    li $v0 11
    li $a0 ')'
    syscall
.end_macro

# Calculate the address
.macro cal_address(%reg_one, %reg_two, %length, %return)	   
    mul %return, %reg_one, %length
    add %return, %return, %reg_two
    sll %return, %return, 2
.end_macro 

# set value from address %matrix + address
.macro set_weight(%matrix, %address, %value)	 
    add %matrix, %matrix, %address
    sw %value, (%matrix)
    sub %matrix, %matrix, %address
.end_macro 

# get value from address %matrix + address
.macro get_weight(%matrix, %address, %return)	 
    add %matrix, %matrix, %address
    lw %return, (%matrix)
    sub %matrix, %matrix, %address
.end_macro 

.macro print_edge(%i, %j)	    # Print (i,j)
    open()
    print_int(%i)
    comma()
    print_int(%j)
    close()
.end_macro 

.macro print_prompt(%prompt)        # Print prompt
    .text
        li $v0, 4
        la $a0, %prompt
        syscall
.end_macro

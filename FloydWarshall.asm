.include "macro.asm"

# Define some important constant
.eqv SELECT_1  1  
.eqv SELECT_2  2
.eqv SELECT_3  3
.eqv SELECT_4  4
.eqv SELECT_5  5
.eqv SELECT_6  6

.data
	weights: .word 0:10000  # space for up to 100x100 weight matrix
	paths: .word 0:10000  # tracing the shortest path between the vertices
	print_matrix: .asciiz "\nMa tran trong so la :\n"
	inf_word: .asciiz "inf"
	inf: .word 2147483647
	
	# keyboard
	twodots: .asciiz " : "
	weight_prompt: .asciiz "Nhap trong so cua canh "
	node_prompt: .asciiz "Nhap so luong dinh cua do thi : "
	
	# file
	file_content: .space 1000
	filename: .asciiz "WeightMatrix.txt"
	file_error: .asciiz "\nMo file khong thanh cong!\n"
	file_success: .asciiz "\nMo file thanh cong!\n"
	error_file: .asciiz "\nMa tran khong hop le!\n"
	
	# trace
	no_path: .asciiz "Khong ton tai duong di "
	shortest_path: .asciiz "Duong di ngan nhat "
	tarrow: .asciiz " -=> "
	
	# menu
	rule: .asciiz "=============================================================================================================\n"
	menu_text: .asciiz "\t\t\t\t\t\tMENU\t\t\t\n"
	input_keyboard: .asciiz "\t1.\tNhap tu ban phim\n"
	input_file: .asciiz "\t2.\tNhap tu file WeightMatrix.txt\n"
	show_matrix: .asciiz "\t3.\tHien thi ma tran hien tai\n"
	show_weight_shortest: .asciiz "\t4.\tChay thuat toan Floyd Warshall\n"
	exit_menu: .asciiz "\t5.\tThoat\n"
	
	# selection
	select_prompt: .asciiz "Vui long nhap yeu cau (1 - 5): "
	select_error_prompt: .asciiz "Nhap sai vui long nhap lai!!!\n"
	waite_key_prompt: .asciiz "\nNhan so 0 de tiep tuc."
	enter_matrix_prompt: .asciiz "Ban chua nhap ma tran. Vui long nhap ma tran bang chuc nang 1 hoac 2!!!"
# $t0 = pointer of weight matrix
# $t1 = number of nodes
# $t2 = flag, = -1 if the matrix is invalid, 0 otherwise
# $t3 = pointer of paths matrix
# $t4 = select in the menu
# $t5 = flag, = -1 if does not exist matrix, 0 ortherwise 
.text 
# main: 
# function: read_weights
# labels:
# loop_input, inner_loop_input, next_row_input, done_input
#
# function: get_weight_input
# labels:
# weight_0, weight_inf, end_input, return
#
# function: print_weight_matrix
# labels: 
# loop_print, inner_loop_print, next_row_print, cond, end_cond, done_print
#
# function: read_weights_file: 
# labels:
# read_file, end_read_file, loop_input_file, done_loop_input_file, inner_loop_input_file, next_row_input_file
# load_byte, cond_digits, digits, error, done_digits, beqz_weight, next_element_file
#
# function: floyd_warshall
# labels:
# loop_i, loop_j, loop_k, end_loop_i, end_loop_j, end_loop_k, cond_inf, cond_inf_
# return_reg_two, exit_cond, exit_min
#
# function: trace_path
# labels:
# trace_i, trace_j, end_trace_i, end_trace_j
# print_path, end_print_path, loop_trace, end_loop_trace
#
#
#
.globl main
# main program
main:
	jal menu
	
	li $v0, 10
	syscall 
# menu
menu:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t5, -1
	show_menu:
		print_prompt(rule)
		print_prompt(menu_text)
		print_prompt(input_keyboard)
		print_prompt(input_file)
		print_prompt(show_matrix)
		print_prompt(show_weight_shortest)
		print_prompt(exit_menu)
		print_prompt(rule)
	
	jal selection
	
	subi $s0, $t4, SELECT_5
	bnez $s0, show_menu
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
# selection
selection:
	# save register
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	print_prompt(select_prompt)
	read_int($t4)
	
	select_1:
		subi $s0, $t4, SELECT_1
		bnez $s0, select_2
		jal read_weights
		jal print_weight_matrix
		jal waite_key
		li $t5, 0
		j select_done
	select_2:
		subi $s0, $t4, SELECT_2
		bnez $s0, select_3
		jal read_weights_file
		bnez $t2, matrix_invalid
		jal print_weight_matrix
		jal waite_key 
		li $t5, 0
		j select_done
		matrix_invalid:
			jal waite_key
		j select_done
	select_3:
		subi $s0, $t4, SELECT_3
		bnez $s0, select_4
		bnez $t5, matrix_error
		jal print_weight_matrix
		jal waite_key
		j select_done
	select_4:
		subi $s0, $t4, SELECT_4
		bnez $s0, select_5
		bnez $t5, matrix_error
		jal floyd_warshall
		jal print_weight_matrix
		jal trace_path
		jal waite_key
		j select_done
	select_5:
		subi $s0, $t4, SELECT_5
		bnez $s0, select_error
		j select_done
	matrix_error:
		print_prompt(enter_matrix_prompt)
		jal waite_key
		j select_done
	select_error:
		print_prompt(select_error_prompt)
		jal waite_key
	select_done:
	# restore registers
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
waite_key:
	# save register
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	waite:
		print_prompt(waite_key_prompt)
		read_int($v0)
		bnez $v0, waite
	
	# restore registers
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# read_weights function
# function using $s1, $s2 to save counter rows, columns
read_weights:
	# save registers
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
   
   	# prompt user for number of nodes
	print_prompt(node_prompt)
	
	read_int($t1)					# $t1 = number of nodes 
	
	# loop to read in weight matrix
	la $t0, weights					# pointer to weights matrix
	la $t3, paths					# pointer to paths matrix
	li $s1, 0					# counter for rows
	loop_input:
		bge $s1, $t1, done_input  # exit loop if counter >= number of nodes

        	# loop for columns
        	li $s2, 0  # counter for columns
        	inner_loop_input:
            		bge $s2, $t1, next_row_input  # exit inner loop if counter >= number of nodes
            
            		move $a1, $s1  # pass row index as first argument
			move $a2, $s2  # pass column index as second argument
			 
            		jal get_weight_input  # call get_weight_input function

            		# store weight in matrix
			sw $v0, ($t0)
            		addi $t0, $t0, 4  # increment pointer

            		addi $s2, $s2, 1  # increment column counter
            		j inner_loop_input

        	next_row_input:
            		addi $s1, $s1, 1  # increment row counter
			j loop_input

    	done_input:
        # print newline
        endl()

    	# restore registers and return
	lw $ra, 0($sp)
    	lw $s1, 4($sp)
	lw $s2, 8($sp)
    	addi $sp, $sp, 12
    	jr $ra

# get_weight_input function
# prompts user for weight of edge(i, j) and returns the input as an integer

get_weight_input:
    	# save registers
    	addi $sp, $sp, -4
    	sw $ra, 0($sp)
    	
	lw $a3, inf 			# $a3 = inf
	
	beq $a1, $a2, weight_0 		# if i == j then weight = 0
	
    	# print message with edge indices
    	print_prompt(weight_prompt)
    	print_edge($a1, $a2)
    	print_prompt(twodots)
   	
    	# read input as integer
    	li $v0, 5
    	syscall
    	
    	bne $v0, $zero, end_input  	# if weight != 0, then end input 
    	j weight_inf 			# else weight = inf
  
	weight_0:			# weight = 0
		li $v0, 0
		j end_input
	weight_inf:			# weight = inf
		lw $v0, inf
	end_input:
		beq $v0, $a3, return	# if weight[i][j] != inf then paths[i][j] = j
		beq $a1, $a2, return
		cal_address($a1, $a2, $t1, $a0) # $a0 = address
		set_weight($t3, $a0, $a2)
	return:
    		# restore registers and return input
    		lw $ra, 0($sp)
    		addi $sp, $sp, 4
    		jr $ra
    	
# print_weight_matrix function
# function using $s1, $s2 to save counter rows, columns
# $a3 to save inf 
print_weight_matrix:
    	# save registers
    	addi $sp, $sp, -12
    	sw $ra, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	
	lw $a3, inf 					# $a3 = inf
	
    	# print message
    	print_prompt(print_matrix)
   	
	# loop to read in weight matrix
	# la $t0, paths
	la $t0, weights					# pointer to weights matrix
	li $s1, 0					# counter for rows
	loop_print:
		bge $s1, $t1, done_print  		# exit loop if counter >= number of nodes

        	# loop for columns
        	li $s2, 0  				# counter for columns
        	inner_loop_print:
            		bge $s2, $t1, next_row_print  	# exit inner loop if counter >= number of nodes
            
			lw $a0, ($t0) 			# a0 = matrix[i][j]
			
			beq $a0, $a3, cond 		# if matrix[i][j] == inf
			
			print_int($a0)			# print matrix[i][j]
			
			j end_cond
			cond:
				bne $s1, $s2, inf_print # if i != j print Inf
				j end_cond
				inf_print:
					print_prompt(inf_word)
			end_cond:
			tab() # print tab
			
            		addi $t0, $t0, 4  		# increment pointer
            		addi $s2, $s2, 1 		# increment column counter
            		j inner_loop_print

        	next_row_print:
        		endl()
			
            		addi $s1, $s1, 1 		# increment row counter
			j loop_print

    	done_print:
        	# print newline
        	endl()
        	
    	# restore registers 
    	lw $ra, 0($sp)
   	lw $s1, 4($sp)
	lw $s2, 8($sp)
   	addi $sp, $sp, 12
    	jr $ra

# read_weights_file function
# function using $s0 to save file descriptor
# function using $s1, $s2 to save counter rows, columns
read_weights_file:
	# save registers
	addi $sp, $sp, -16
	sw $ra, 0($sp)
   	sw $s0, 4($sp)
   	sw $s1, 8($sp)
   	sw $s2, 12($sp)
	# Open the file
    	li $v0, 13           # system call for opening a file
    	la $a0, filename     # load the file name into $a0
    	li $a1, 0            # load the file mode (0 = read-only)
    	li $a2, 0	     # mode is ignored
    	syscall              # execute the system call
    	
    	# Check successfully opened file
    	bgez $v0, read_file  # if $v0 < 0 then file open error
    	# print error message
	print_prompt(file_error)
    	
    	j end_read_file
    	
    	read_file:
    		move $s0, $v0        # save the file descriptor in $s0
    		
    		# print success message
    		print_prompt(file_success)
    		
	# Read the weights matrix from the file
    		li $v0, 14           # system call for reading from a file
    		move $a0, $s0        # move the file descriptor to $a0
    		la $a1, file_content # 
    		la $a2, 1000         # load the size of each element to read
    		syscall              # execute the system call
		
    		# close file
    		li $v0, 16         
    		move $a0, $s0        
    		syscall   
    	end_read_file:
    
    	la $a1, file_content
    	
	# endl()
    	# read number node
    	lb $t1, 0($a1)
    	addi $t1, $t1, -48
    	# print_int($t1)
    	# endl()
    	
    	addi $a1, $a1, 3
   
    	# loop to read in weight matrix
	la $t0, weights					# pointer to weights matrix
	la $t3, paths					# pointer to paths matrix
	li $s1, 0					# counter for rows	   
	loop_input_file:
		bge $s1, $t1, done_input_file  # exit loop if counter >= number of nodes

        	# loop for columns
        	li $s2, 0  # counter for columns
        	inner_loop_input_file:
            		bge $s2, $t1, next_row_input_file  # exit inner loop if counter >= number of nodes
			
			li $a3, 0
			li $s0, 10
			li $s3, 0				# flag		
            		# store weight in matrix
            		load_byte:
            			lb $a2, ($a1)
            			addi $a2, $a2, -48
            		
            			bgez $a2, cond_digits		# if this character is digit, 0 <= $a2 <= 9

				beq $s3, $zero, error
				li $s3, 0
            			move $a2, $a3			# $a2 = weight[i][j]
            			li $a3, 0
            			j done_digits
            		
            		cond_digits:
            			blt $a2, $s0, digits
            			j error
            		digits:
            			li $s3, 1
            			mul $a3, $a3, $s0
            			add $a3, $a3, $a2
            			addi $a1, $a1, 1  # increment pointer file
            			j load_byte
            		error:
            			print_prompt(error_file)
            			li $t2, -1
            			j done_input_file
            		done_digits:	
            		
			sw $a2, ($t0)
			
			bne $s1, $s2, beqz_weight  	# if i != j and weight = 0 then weight = inf
			bnez $a2, error			# if i == 1 and weight != 0 then error
			
			j next_element_file
			beqz_weight:
				beqz $a2, weight_inf_file
				cal_address($s1, $s2, $t1, $a0) # $a0 = address
				set_weight($t3, $a0, $s2)
				j next_element_file
				weight_inf_file:
					lw $a2, inf
					sw $a2, ($t0)
			
			next_element_file:
            			addi $t0, $t0, 4  # increment pointer
				addi $a1, $a1, 1  # increment pointer file
            			addi $s2, $s2, 1  # increment column counter
            			j inner_loop_input_file

        	next_row_input_file:
        		addi $a1, $a1, 1  # increment pointer file
            		addi $s1, $s1, 1  # increment row counter
			j loop_input_file

    	done_input_file:
    	# restore registers and return
	lw $ra, 0($sp)
    	lw $s0, 4($sp)
    	lw $s1, 8($sp)
    	lw $s2, 12($sp)
    	addi $sp, $sp, 16
    	jr $ra
    	
# floyd_warshall function
floyd_warshall:
	# save registers
	addi $sp, $sp, -28
	sw $ra, 0($sp)
    	sw $s0, 4($sp)         	# counter k
    	sw $s1, 8($sp)		# counter i
    	sw $s2, 12($sp)		# counter j
    	sw $s3, 16($sp)		# matrix[i, k]
    	sw $s4, 20($sp)		# matrix[k, j]
    	sw $s5, 24($sp)		# matrix[i, j]
    	
    	lw $a3, inf 		# $a3 = inf
    	
    	# loop 	
    	la $t0, weights							# pointer to weights matrix		
    	la $t3, paths							# pointer to paths matrix
	li $s0, 0							# counter for k
	loop_k:
		bge $s0, $t1, end_loop_k  				# exit loop if k >= number of nodes
		# loop for i
        	li $s1, 0  						# counter for i
        	loop_i:
        		bge $s1, $t1, end_loop_i  			# exit loop if i >= number of nodes
     
        		# loop for j
        		li $s2, 0					# counter for j
        		loop_j:
        			bge $s2, $t1, end_loop_j  		# exit loop if j >= number of nodes
        			
        			cal_address($s1, $s0, $t1, $a0)		# [i, k]
        			cal_address($s0, $s2, $t1, $a1)		# [k, j]
        			cal_address($s1, $s2, $t1, $a2)		# [i, j]
        			get_weight($t0, $a0, $s3)		# $s3 = weight[i, k]              			       	       			       					
        			get_weight($t0, $a1, $s4)		# $s4 = weight[k, j]
        			get_weight($t0, $a2, $s5)		# $s5 = weight[i, j]
        			bne $s3, $a3, cond_inf 			# if weight[i][k] != inf
        			j exit_cond
        			cond_inf:
        				bne $s4, $a3, cond_inf_ 	# if weight[k][j] != inf
        				j exit_cond
        			cond_inf_:
        				add $s3, $s3, $s4		# $s3 = weight[i, k] + weight[k, j]
        				# min($s5, $s3, $s5)	 	# $s5 = min(weight[i, j], weight[i, k] + weight[k, j])
        				
        				bgt $s5, $s3, return_reg_two    # if a >= b  return b
    					# move %return, %reg_one		     # else return a
    					j exit_min
  
    					return_reg_two:
						move $s5, $s3
						cal_address($s1, $s2, $t1, $a2)		# [i, j]
						cal_address($s1, $s0, $t1, $a0)		# [i, k]
						get_weight($t3, $a0, $s3)		# $s3 = paths[i, k]
						set_weight($t3, $a2, $s3)		# paths[i, j] = paths[i, k]
    					exit_min:
    					
        				set_weight($t0, $a2, $s5)		# weights[i, j] = $s5
        				
        			exit_cond:
        			# nothing
        			
        			addi $s2, $s2, 1 			# increment j
        			j loop_j
        		end_loop_j:
        		
            		addi $s1, $s1, 1 				# increment i
            		j loop_i
        	end_loop_i:
        	
        	addi $s0, $s0, 1 					# increment k
        	j loop_k
	end_loop_k:
    	
    	# restore registers 
    	lw $ra, 0($sp)
    	lw $s0, 4($sp)         	
    	lw $s1, 8($sp)		
    	lw $s2, 12($sp)		
    	lw $s3, 16($sp)		
    	lw $s4, 20($sp)		
    	lw $s5, 24($sp)	
    	addi $sp, $sp, 28
    	jr $ra	
# tracing path
trace_path:
	# save registers
	addi $sp, $sp, -16
	sw $ra, 0($sp)
    	sw $s0, 4($sp)         	# counter i
    	sw $s1, 8($sp)		# counter j
    	sw $s2, 12($sp)		# counter trace
    	
    	lw $a3, inf 		# $a3 = inf
    	
    	# loop 	
    	la $t0, weights							# pointer to weights matrix		
    	la $t3, paths							# pointer to paths matrix
	li $s0, 0							# counter for i
	trace_i:
		bge $s0, $t1, end_trace_i  				# exit loop if i >= number of nodes
		# loop for j
        	li $s1, 0  						# counter for j
        	trace_j:
        		bge $s1, $t1, end_trace_j  			# exit loop if j >= number of nodes
     			
     			lw $a2, ($t0)					# $a2 = weight[i, j]
     			bne $a2, $a3, print_path			# if weight[i, j] == inf then no path
     			print_prompt(no_path)
     			print_edge($s0, $s1)
     			endl()
			j done_print_path
     			
     			print_path:
     				beq $s0, $s1, done_print_path		# if i == j, then continue
     				
     				print_prompt(shortest_path)
     				print_edge($s0, $s1)
     				print_prompt(twodots)
     				
     				add $s2, $s0, $zero			# $s2 = i
     				
     				loop_trace:
					beq $s2, $s1, end_loop_trace	# if $s2 == j then end loop
					
					print_int($s2)
					print_prompt(tarrow)
					
					cal_address($s2, $s1, $t1, $a2)
					get_weight($t3, $a2, $s2)	# $s2 = path[$s2][j]
					j loop_trace
     				end_loop_trace:
     				print_int($s1)
     				endl()
     			done_print_path:
     			# nothing
     			
     			addi $t0, $t0, 4				# increment pointer
        		addi $s1, $s1, 1 				# increment j
        		j trace_j
        	end_trace_j:
        	
        	addi $s0, $s0, 1 					# increment i
        	j trace_i
	end_trace_i:
	
    	# restore registers 
    	lw $ra, 0($sp)
    	lw $s0, 4($sp)         	
    	lw $s1, 8($sp)		
    	lw $s2, 12($sp)		
    	addi $sp, $sp, 16
    	jr $ra	

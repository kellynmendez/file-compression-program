# File Compression and Uncompression Program
# @author Kellyn Mendez
# 	Compresses a given input file using an RLE algorithm:
#	Prints the data, compresses then prints the compressed data, then uncompresses the data

.include "compression_program_macro.asm"

.data
filename:		.space		32
buffer:			.space		1024
prompt:			.asciiz		"Please enter the filename to compress or <enter> to exit: "
error_msg:		.asciiz		"Error opening file. Program terminating."
orig_data_msg:		.asciiz		"Original data: \n"
comp_data_msg:		.asciiz		"Compressed data: \n"
uncomp_data_msg:	.asciiz		"Uncompressed data: \n"
orig_size_msg:		.asciiz		"Original file size: "
comp_size_msg:		.asciiz		"Compressed file size: "
ptr:			.word		0
orig_size:		.word		0
comp_size:		.word		0

.text
main:		alloc_heap_mem (1024, ptr)		# Allocating 1024 bytes of dynamic memory
	
		########## Main program loop ########## 
	
file_loop:	get_user_str (prompt, filename, 31)	# Getting filename
		li	$t0, 0xA
		print_char ($t0)
	
		# Loop to change the newline character at the end of the filename to null terminating
		
		la	$t0, filename			# Loading filename address
		lbu	$t2, ($t0)			# If user entered nothing, exit the program
		beq	$t2, 0xA, exit
	
newline_loop:	beq	$t2, 0xA, open_file		# If it's a newline, branch
		addi	$t0, $t0, 1			# If it's not, move on to next byte
		lbu	$t2, ($t0)			# Loading the next byte
		j	newline_loop			
		
		
open_file:	sb	$zero, ($t0)			# Changing newline to null terminating
		
		# Opening, reading, and closing the file
		
		open_file (filename)
		ble	$v0, $zero, error		# If $v0 <= 0 there's been an error;
							#     print error message and exit
		move	$s0, $v0			# Saving file descriptor in $s0
		read_file ($s0, buffer, 1024)
		move	$s1, $v0			# Saving the number of bytes read in $s1		
		close_file ($s0)
		
		# Outputting the original data to the console
		
		print_str (orig_data_msg)
		print_str (buffer)
		li	$t0, 0xA
		print_char ($t0)			# Printing newline
		
		# Calling function to compress the input
		
		la	$a0, buffer			# Setting parameters
		la	$a1, ptr
		move	$a2, $s1
		jal	comp_input			# Jumping to function
		move	$s2, $v0
		
		# Calling function to print the compressed data
		
		
		print_str (comp_data_msg)
		la	$a0, ptr			# Setting parameters
		move	$a1, $s2
		jal	print_comp			# Calling function
		li	$t0, 0xA			# Printing newline
		print_char ($t0)
		
		# Calling function to uncompress and print the data
		
		print_str (uncomp_data_msg)
		la	$a0, ptr			# Setting parameters
		move	$a1, $s2
		jal	uncomp_data			# Calling function
		li	$t0, 0xA			# Printing newline
		print_char ($t0)
		
		# Printing the number of bytes in the original and compressed data
		
		print_str (orig_size_msg)
		print_int ($s1)
		li	$t0, 0xA			# Printing newline
		print_char ($t0)
		
		print_str (comp_size_msg)
		print_int ($s2)
		li	$t0, 0xA			# Printing newline
		print_char ($t0)
		print_char ($t0)
		
		# Restarting main file loop
		
		j	file_loop

exit:		# Exit program
		li	$v0, 10
		syscall

error:		# Printing error message then exiting program
		print_str (error_msg)
		j	exit


################################### FUNCTIONS #######################################

#----------------------------- COMPRESS INPUT FUNCTION ------------------------------
# Compresses the input of the given input buffer using a run-length encoding algorithm,
#    placing the compressed data in the given compression buffer
#    Example: 'AABBBC' would be encoded as 'A2B3C1'
	# $a0 = address of the input buffer
	# $a1 = address of the compression buffer
	# $a2 = size of the original file
	# Returns size of compressed data in $v0

comp_input:	move	$t0, $a0		# Place in input buffer
		move	$t1, $zero		# Track size of compressed data
		move	$t2, $a1		# Place in compression buffer
		lbu	$t3, ($t0)		# Track current character in input buffer
		move	$t4, $t3		# Track current byte being checked in input buffer
		move	$t5, $zero		# To be used to count number of bytes in a row
		move	$t6, $zero		# Track number of bytes read from input so far
		
comp_loop:	beq	$t6, $a2, store_char	# If the number of bytes read so far is equal to size of input
						#   finished reading data
		bne	$t3, $t4, store_char	# If the current character and the byte being checked are not equal,
						#   store current character and its number to the compression buffer
		addi	$t5, $t5, 1		# Updating character number
		addi	$t6, $t6, 1		# Updating number of bytes read
		addi	$t0, $t0, 1		# Moving to next byte
		lbu	$t4, ($t0)		# Loading next byte
		j	comp_loop
		
store_char:	# Storing character and its number to the compression buffer
		
		sb	$t3, ($t2)		# Storing the character
		addi	$t2, $t2, 1		# Moving to next byte in compression buffer
		sb	$t5, ($t2)		# Storing number of that character
		addi	$t2, $t2, 1		# Moving to next byte in compression buffer
		
		# Updating values
		
		move	$t3, $t4		# Updating the current character to the current 
						#    byte being checked
		move	$t5, $zero		# Resetting character number
		addi	$t1, $t1, 2		# Updating size of compression buffer
		
		# Checking for end of data / looping back if not at the end
		
		beq	$t6, $a2, ex_comp_fn	# If the number of bytes read so far is equal to size of input
						#   finished reading data
		j	comp_loop

ex_comp_fn:	move	$v0, $t1		# Returning size of compression buffer
		jr	$ra



#-------------------------- OUTPUT COMPRESSED DATA FUNCTION -------------------------
# Printing the compressed data from the given compression buffer
	# $a0 = address of the compression buffer
	# $a1 = size of the compressed data

print_comp:	move	$t1, $zero		# i = 0
		move	$t0, $a0		# Place in buffer
		
print_loop:	beq	$t1, $a1, ex_print_fn	# If num chars read == size of the data, exit
		lbu	$t2, ($t0)
		print_char ($t2)
		addi	$t1, $t1, 1		# i++
		addi	$t0, $t0, 1		# Moving to next byte
		
		lbu	$t2, ($t0)
		print_int ($t2)
		addi	$t1, $t1, 1		# i++
		addi	$t0, $t0, 1		# Moving to next byte
		
		j	print_loop
		
ex_print_fn:	jr	$ra



#----------------------------- UNCOMPRESS DATA FUNCTION -----------------------------
# Uncompressing the data from the given compression buffer and outputing uncompressed
#    data to console
	# $a0 = address of the compression buffer
	# $a1 = size of the compressed data

uncomp_data:	move	$t1, $zero		# i = 0
		move	$t0, $a0		# Place in buffer

uncomp_loop:	beq	$t1, $a1, ex_uncomp_fn	# if i == size of compressed data, done printing
		move	$t4, $zero		# Track num times character has been printed
		lbu	$t2, ($t0)		# Loading the character
		addi	$t0, $t0, 1		# Moving to next byte
		lbu	$t3, ($t0)		# Loading the number
		addi	$t0, $t0, 1		# Moving to next byte
		addi	$t1, $t1, 2		# i += 2
		
print_char_loop:
		beq	$t3, $t4, uncomp_loop	# If num times char has been printed = the number it should
						#   be printed, jump back to loop
		print_char ($t2)
		addi	$t4, $t4, 1		# Printing char and updating num times its been printed
		j 	print_char_loop
		
ex_uncomp_fn:	jr	$ra



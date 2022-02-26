# Macro file for file compression and uncompression program
# @author Kellyn Mendez


# Print integer
.macro print_int (%int)
	li 	$v0, 1		# Loading syscall for printing integer
	move 	$a0, %int	# Loading integer
	syscall
.end_macro

# Print character
.macro print_char (%char)
	li	$v0, 11		# Loading syscall for printing character
	move	$a0, %char	# Loading character
	syscall
.end_macro

# Print string
.macro print_str (%str)
	li	$v0, 4		# Loading syscall for printing string
	la	$a0, %str	# Loading string
	syscall
.end_macro

# Get a user input string
.macro get_user_str (%prompt, %buffer, %num_bytes)
	print_str (%prompt)	# Printing the prompt
	li	$v0, 8		# Loading syscall for reading string
	la	$a0, %buffer	# Loading address of input buffer
	li	$a1, %num_bytes	# Loading number of bytes to read
	syscall
.end_macro

# Open a file - after opening, file descriptor is stored in $s0
.macro open_file (%filename)
	li	$v0, 13		# Loading syscall for opening file
	la	$a0, %filename	# Loading filename
	li	$a1, 0		# Opening for reading
	li	$a2, 0		# Ignoring mode
	syscall
.end_macro

# Read from the file - after reading, number of bytes read is in $v0
.macro read_file (%file_desc, %buffer, %buff_len)
	li	$v0, 14		# Loading syscall for reading file
	move	$a0, %file_desc	# Loading file descriptor
	la	$a1, %buffer	# Loading buffer address
	li	$a2, %buff_len	# Loading buffer length
	syscall
.end_macro

# Close a file
.macro close_file (%file_desc)
	li	$v0, 16		# Loading syscall for closing file
	move	$a0, %file_desc	# Loading file descriptor
	syscall
.end_macro

# Allocate memory on the heap
.macro alloc_heap_mem (%num_bytes, %ptr)
	li	$v0, 9		# Loading syscall to allocate heap memory
	li	$a0, %num_bytes	# Loading number of bytes to allocate
	syscall
	sw	$v0, %ptr	# Saving the pointer
.end_macro


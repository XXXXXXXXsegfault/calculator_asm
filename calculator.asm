.cui
@msg1
.string "Enter an expression (\"(1+2+3)*(1-2+3)/2\") to calculate it. Enter \"quit\" to exit.\n"
@msg2
.string ">> "
@msg3
.string "Error\n"
@out_format
.string "%.5f"

@putchar
# 8 -- c
push %rax
push %rcx
push %rdx
push %r8
push %r9
push %r10
push %r11
push %rbp
mov %rsp,%rbp
and $0xf0,%spl
mov 72(%rbp),%cl
sub $24,%rsp
movzbl %cl,%ecx
push %rcx
.dllcall "msvcrt.dll" "putchar"
mov %rbp,%rsp
pop %rbp
pop %r11
pop %r10
pop %r9
pop %r8
pop %rdx
pop %rcx
pop %rax
ret
@getchar
push %rcx
push %rdx
push %r8
push %r9
push %r10
push %r11
push %rbp
mov %rsp,%rbp
and $0xf0,%spl
sub $32,%rsp
.dllcall "msvcrt.dll" "getchar"
mov %rbp,%rsp
pop %rbp
pop %r11
pop %r10
pop %r9
pop %r8
pop %rdx
pop %rcx
ret
@puts
# %rax -- str
push %rax
push %rcx
@puts_loop
mov (%rax),%cl
test %cl,%cl
je @puts_end
push %rcx
call @putchar
pop %rcx
inc %rax
jmp @puts_loop
@puts_end
pop %rcx
pop %rax
ret

@str_shift
# %rax -- index
push %rax
push %rcx
@str_shift_loop
mov @_$DATA+4096+1(%rax),%cl
mov %cl,@_$DATA+4096(%rax)
inc %rax
test %cl,%cl
jne @str_shift_loop
pop %rcx
pop %rax
ret
@str_shift2
# %rax -- index
# %rdx -- end
push %rax
push %rcx
push %rdx
@str_shift_loop2
mov @_$DATA+4096(%rdx),%cl
mov %cl,@_$DATA+4096(%rax)
inc %rax
inc %rdx
test %cl,%cl
jne @str_shift_loop2
pop %rdx
pop %rcx
pop %rax
ret
@str_insert_sharp
# %rax -- index
push %rax
push %rcx
push %rdx
xor %edx,%edx
@str_insert_sharp_loop
mov @_$DATA+4096(%rax),%cl
inc %rax
inc %rdx
test %cl,%cl
jne @str_insert_sharp_loop
@str_insert_sharp_loop2
mov @_$DATA+4096-1(%rax),%cl
mov %cl,@_$DATA+4096(%rax)
dec %rax
dec %rdx
jne @str_insert_sharp_loop2
movb $35,@_$DATA+4096(%rax)
pop %rdx
pop %rcx
pop %rax
ret
@num_shift
# %rcx -- index
push %rax
push %rcx
@num_shift_loop
mov @_$DATA+6144+8(%rcx),%rax
mov %rax,@_$DATA+6144(%rcx)
add $8,%rcx
cmp $16384-8,%rcx
jb @num_shift_loop
pop %rcx
pop %rax
ret

@convert_numbers
xor %eax,%eax
xor %ecx,%ecx
@check_sharp
mov @_$DATA+4096(%rax),%dl
test %dl,%dl
je @check_sharp_end
cmp $35,%dl
je @convert_numbers_err
inc %rax
jmp @check_sharp
@check_sharp_end

xor %eax,%eax
@conv_loop
mov @_$DATA+4096(%rax),%dl
inc %rax
test %dl,%dl
je @convert_numbers_end
sub $48,%dl
cmp $10,%dl
jae @conv_loop
dec %rax

push %rax
push %rcx

push %r8
push %r9
push %r10
push %r11
push %rbp
mov %rsp,%rbp
sub $48,%rsp
and $0xf0,%spl
lea @_$DATA+4096(%rax),%rcx
lea 32(%rsp),%rdx
.dllcall "msvcrt.dll" "strtod"
mov 32(%rsp),%rdx
sub $@_$DATA+4096,%rdx
mov %rbp,%rsp
pop %rbp
pop %r11
pop %r10
pop %r9
pop %r8
pop %rcx
pop %rax
movsd %xmm0,@_$DATA+6144(%rcx)
call @str_shift2
call @str_insert_sharp
add $8,%rcx

jmp @conv_loop

@convert_numbers_end
xor %eax,%eax
ret
@convert_numbers_err
mov $1,%eax
ret

@print_number
# %rax -- num
push %rbp
mov %rsp,%rbp
sub $32,%rsp
and $0xf0,%spl
mov $@out_format,%rcx
mov %rax,%rdx
movq %rax,%xmm1
mov %rcx,(%rsp)
mov %rdx,8(%rsp)
.dllcall "msvcrt.dll" "printf"
mov %rbp,%rsp
pop %rbp
ret

@calculate_expr
xor %ebx,%ebx

xor %eax,%eax
xor %ecx,%ecx
xor %r8d,%r8d
xor %r9d,%r9d
@parentheses_loop
cmpb $0,@_$DATA+4096(%rax)
je @parentheses_loop_end
mov @_$DATA+4096(%rax),%edx
shl $8,%edx
# "(#)"
cmp $0x29232800,%edx
jne @expr_not_parentheses
call @str_shift
inc %rax
call @str_shift
dec %rax
inc %ebx
@expr_not_parentheses
inc %rax
jmp @parentheses_loop
@parentheses_loop_end
xor %esi,%esi
xor %edi,%edi
xor %eax,%eax
@locate_parentheses
cmpb $0,@_$DATA+4096(%rax)
je @locate_parentheses_end
cmpb $0x29,@_$DATA+4096(%rax)
je @locate_parentheses_end
inc %rax
cmpb $0x23,@_$DATA+4096-1(%rax)
jne @locate_parentheses_not_number
add $8,%r9
@locate_parentheses_not_number
cmpb $0x28,@_$DATA+4096-1(%rax)
jne @locate_parentheses
mov %rax,%rsi
mov %r9,%r8
jmp @locate_parentheses
@locate_parentheses_end
lea -2(%rax),%rdi

mov %rsi,%rax
mov %r8,%rcx
@locate_mul_div
cmp %rdi,%rax
jge @locate_mul_div_end
inc %rax
cmpb $0x23,@_$DATA+4096-1(%rax)
jne @locate_mul_div
add $8,%rcx
cmpw $0x232a,@_$DATA+4096(%rax)
je @found_mul
cmpw $0x232f,@_$DATA+4096(%rax)
jne @locate_mul_div
# div
push %rdx
movsd @_$DATA+6144(%rcx),%xmm0
mov $0x3e7ad7f29abcaf48,%rdx
movq %rdx,%xmm1
pop %rdx
comisd %xmm1,%xmm0
ja @div_not_zero
push %rdx
movsd @_$DATA+6144(%rcx),%xmm0
mov $0xbe7ad7f29abcaf48,%rdx
movq %rdx,%xmm1
pop %rdx
comisd %xmm1,%xmm0
ja @locate_mul_div
@div_not_zero
inc %ebx
push %rax
push %rcx
push %rdx
movsd @_$DATA+6144-8(%rcx),%xmm0
movsd @_$DATA+6144(%rcx),%xmm1
divsd %xmm1,%xmm0
pop %rdx
pop %rcx
sub $8,%rcx
call @num_shift
movsd %xmm0,@_$DATA+6144(%rcx)
pop %rax
call @str_shift
call @str_shift
jmp @expr_end
@found_mul
inc %ebx
push %rax
push %rcx
push %rdx
movsd @_$DATA+6144-8(%rcx),%xmm0
movsd @_$DATA+6144(%rcx),%xmm1
mulsd %xmm1,%xmm0

pop %rdx
pop %rcx
sub $8,%rcx
call @num_shift
movsd %xmm0,@_$DATA+6144(%rcx)
pop %rax
call @str_shift
call @str_shift

jmp @expr_end

@locate_mul_div_end
mov %rsi,%rax
mov %r8,%rcx
@locate_add_sub
cmp %rdi,%rax
jge @locate_add_sub_end
inc %rax
cmpb $0x23,@_$DATA+4096-1(%rax)
jne @locate_add_sub
add $8,%rcx
cmpw $0x232b,@_$DATA+4096(%rax)
je @found_add
cmpw $0x232d,@_$DATA+4096(%rax)
jne @locate_add_sub
# sub
inc %ebx
push %rax
push %rcx
push %rdx
movsd @_$DATA+6144-8(%rcx),%xmm0
movsd @_$DATA+6144(%rcx),%xmm1
subsd %xmm1,%xmm0
pop %rdx
pop %rcx
sub $8,%rcx
call @num_shift
movsd %xmm0,@_$DATA+6144(%rcx)
pop %rax
call @str_shift
call @str_shift

jmp @expr_end
@found_add
inc %ebx
push %rax
push %rcx
push %rdx
movsd @_$DATA+6144-8(%rcx),%xmm0
movsd @_$DATA+6144(%rcx),%xmm1
addsd %xmm1,%xmm0
pop %rdx
pop %rcx
sub $8,%rcx
call @num_shift
movsd %xmm0,@_$DATA+6144(%rcx)
pop %rax
call @str_shift
call @str_shift


@locate_add_sub_end

@expr_end
mov %ebx,%eax
ret

.entry
mov $@msg1,%rax
call @puts

@main_loop
mov $@msg2,%rax
call @puts
xor %ecx,%ecx
@read_loop
call @getchar
cmp $10,%al
je @read_loop_end
cmp $2047,%ecx
je @read_loop
mov %al,@_$DATA+4096(%rcx)
inc %ecx
jmp @read_loop
@read_loop_end
movb $0,@_$DATA+4096(%rcx)
cmp $4,%ecx
jne @NoExit
# quit
cmpl $0x74697571,@_$DATA+4096
je @End
@NoExit
cmp $0,%ecx
je @main_loop
call @convert_numbers
test %eax,%eax
jne @error
@calculate_loop
call @calculate_expr
test %eax,%eax
jne @calculate_loop
cmpw $0x0023,@_$DATA+4096
je @good_result
@error
mov $@msg3,%rax
call @puts
jmp @main_loop
@good_result
mov @_$DATA+6144,%rax
call @print_number
pushq $10
call @putchar
add $8,%rsp
jmp @main_loop
@End
ret
.datasize 73728
# 4096 -- str
# 6144 -- values
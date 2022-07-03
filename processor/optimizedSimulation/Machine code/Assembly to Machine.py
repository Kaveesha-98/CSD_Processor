#To convert the assembly code into the machine code

list0 = ["and", "or", "sl", "sra", "srl", "add", "sub", "xor", "clt", "cltu"]
list1 = ["andi", "ori", "sli", "srai", "srli", "addi", "subi", "xori", "clti", "cltui"]
list2 = ["load", "store"]
list3 = ["beqz", "bgtz"]
list4 = ["mov", "jump", "link", "jal"]

fhandle = open("input1.txt", "r")
ins_list = []
for line in fhandle:
    line = line.rstrip()
    ins_list.append(line)

final_output = ""


def alu_inst(sections_of_inst):
    dict_a = {"and" : "1010", "or" : "1000", "sl" : "0111", "sra" : "1001", "srl" : "1101", "add" : "1111", "sub" : "1110", "xor" : "0011", "clt" : "0100", "cltu" : "0101" }

    global final_output
    list = []
    list.append("010")
    
    mc_opcode = dict_a[sections_of_inst[0]]
    
    operand1 = sections_of_inst[1][1:]
    mc_reg1 = format(int(operand1), "04b")

    operand2 = sections_of_inst[2][1:]
    mc_reg2 = format(int(operand2), "04b")

    list.insert(0, "0")
    list.insert(0, mc_reg2)
    list.insert(0, mc_opcode)
    list.insert(0, mc_reg1)

    for part in list:
        final_output += part


def alu_imme_inst(sections_of_inst):
    dict_b = {"andi" : "1010", "ori" : "1000", "sli" : "0111", "srai" : "1001", "srli" : "1101", "addi" : "1111", "subi" : "1110", "xori" : "0011", "clti" : "0100", "cltui" : "0101" }

    global final_output
    list = []
    list.append("110")
    mc_opcode = dict_b[sections_of_inst[0]]
    
    operand1 = sections_of_inst[1][1:]
    mc_reg1 = format(int(operand1), "04b")

    if int(sections_of_inst[2]) >= 0:
        immediate = format(int(sections_of_inst[2]), "05b")
    else:
        immediate = bin(int(sections_of_inst[2]) % (1<<5))[2:]

    list.insert(0, immediate)
    list.insert(0, mc_opcode)
    list.insert(0, mc_reg1)

    for part in list:
        final_output += part


def load_store_inst(sections_of_inst):
    dict_c = {"load" : "100", "store" : "101"}

    global final_output
    list = []
    mc_main_opcode = dict_c[sections_of_inst[0]]

    operand1 = sections_of_inst[1][1:]
    mc_reg1 = format(int(operand1), "04b")

    operand2 = sections_of_inst[2][1:]
    mc_reg2 = format(int(operand2), "04b")

    if int(sections_of_inst[3]) >= 0:
        immediate = format(int(sections_of_inst[3]), "05b")
    else:
        immediate = bin(int(sections_of_inst[3]) % (1<<5))[2:]

    list.insert(0, mc_main_opcode)
    list.insert(0, immediate)
    list.insert(0, mc_reg2)
    list.insert(0, mc_reg1)    

    for part in list:
        final_output += part


def branch_inst(sections_of_inst):
    dict_d = {"beqz" : "1", "bgtz" : "0"}

    global final_output
    list = []
    list.append("011")
    mc_opcode = dict_d[sections_of_inst[0]]
    
    operand1 = sections_of_inst[1][1:]
    mc_reg1 = format(int(operand1), "04b")

    if int(sections_of_inst[2]) >= 0:
        immediate = format(int(sections_of_inst[2]), "09b")
    else:
        immediate = bin(int(sections_of_inst[2]) % (1<<9))[2:]
    print(immediate)
    immediate = immediate[:-1]

    list.insert(0, mc_opcode)
    list.insert(0, immediate)
    list.insert(0, mc_reg1)

    for part in list:
        final_output += part


def move_type_inst(sections_of_inst):
    dict_e = {"mov" : "0000", "jump" : "0010", "link" : "0001", "jal" : "0011"}

    global final_output
    list = []
    list.append("111")
    mc_opcode = dict_e[sections_of_inst[0]]
    
    if sections_of_inst[0] == "jump":
        mc_reg1 = "0000"
    else:
        operand1 = sections_of_inst[1][1:]
        mc_reg1 = format(int(operand1), "04b")

    if sections_of_inst[0] == "link":
        mc_reg2 = "0000"
    else:
        operand2 = sections_of_inst[2][1:]
        mc_reg2 = format(int(operand2), "04b")

    list.insert(0, "0")
    list.insert(0, mc_reg2)
    list.insert(0, mc_opcode)
    list.insert(0, mc_reg1)

    for part in list:
        final_output += part

for index in range(len(ins_list)):
    instruction = ins_list[index]
    
    print(instruction)
    
    sections_of_inst = instruction.split()
    opcode = sections_of_inst[0]

    for i in range(5):
        name = globals()["list" + str(i)]
        if opcode in name:
            type = i
            break

    if type == 0:
        alu_inst(sections_of_inst)
    elif type == 1:
        alu_imme_inst(sections_of_inst)
    elif type == 2:
        load_store_inst(sections_of_inst)
    elif type == 3:
        branch_inst(sections_of_inst)
    elif type == 4:
        move_type_inst(sections_of_inst)
    

    if index < len(ins_list)-1:
        final_output += "\n"

file = open("output1.txt", "w")
file.write(final_output)
file.close()

next_fhandle = open("expected_output1.txt", "r")
check = next_fhandle.read()

if final_output == check:
    print("PASS")
else:
    print("FAIL")


#output instructions as bytes
opcodefile = open("output1.txt", "r")
instByteFile = open("instructions.txt", "w+")
ins_list = []
for line in opcodefile:
    line = line.strip()
    leading_byte = line[8:]
    trailing_byte = line[0:8]
    dec_leading_byte = int(leading_byte, 2)
    dec_trailing_byte = int(trailing_byte, 2)
    #print (dec_leading_byte)
    #print (dec_trailing_byte)
    instByteFile.write(str(dec_leading_byte) + "\n" + str(dec_trailing_byte) + "\n")
    
instByteFile.close()
opcodefile.close()
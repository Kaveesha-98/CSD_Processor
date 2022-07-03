op_code = {"add" : "1111010", "sub" : "1110010" }

fhandle = open("input1.txt", "r")
ins_list = []
for line in fhandle:
    line = line.rstrip()
    ins_list.append(line)

output = ""
for index in range(len(ins_list)):
    steps = ins_list[index].split()
    list1 = []
    output1 = ""

    opcode = op_code[steps[0]]
    list1.append(opcode[:4])
    list1.append(opcode[4:])
    oper1 = steps[1][-1]

    list1.insert(0, format(int(oper1), "04b"))
    oper2 = steps[2][-1]
    value = format(int(oper2), "04b")
    list1.insert(2, value+"0")

    for i in list1:
        output1 += i

    if index < len(ins_list)-1:
        output1 += "\n"
    #print(output1)

    output += output1

file = open("output1.txt", "w")
file.write(output)
file.close()
print("Done")

    

    

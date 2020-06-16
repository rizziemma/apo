#input
source = open("properties.csv", "r")

#output
ref = open("../src/resources/properties_ref.json", "w")
ref.write('{"data":[')


net = open("../src/resources/properties_net.json", "w")
net.write('.name "Properties"\n.type PPN\n')
places = ""
transitions = ""
flows = ""

next(source) #skip first line

first = True

for line in source :
	data = line.strip("\n").split(";");
	
	if(data[0] == "1") : #places
		#ref
		if not first :
			ref.write(',\n')
		ref.write('{ "name":"'+data[1].replace(" ", "-")+'",'
			+'"aka":"'+data[2]+'",'
			+'"def":"'+data[3]+'",'
			+'"ref":"'+data[4]+'"}')
		first = False
		
		#net
		places +=data[1].replace(" ", "-")+"\n"
		
	if(data[0]== "2") : #transitions
		ref.write(',\n')
		ref.write('{ "name":"'+data[1].replace(" ", "-")+'",'
			+'"def":"'+data[4]+'",'
			+'"aka":"''",'
			+'"ref":"'+data[5]+'"}')
			
		transitions +=data[1]+"\n"
		flows += data[1] + ": {" + data[2] + "} -> {" + data[3] + "}\n"
		

ref.write("] }")

net.write("\n.places\n"+places)
net.write("\n.transitions\n"+transitions)
net.write("\n.flows\n"+flows)


source.close()
ref.close()
net.close()

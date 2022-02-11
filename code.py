fbxname = "FBXASC231FBXASC170FBXASC151FBXASC229FBXASC184FBXASC152"
names = [chr(int(i)) for i in fbxname.split("FBXASC")[1:]]
s = "".join(names)
print(s.encode("iso-8859-1").decode("utf-8"))

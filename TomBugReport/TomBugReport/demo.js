require('TOMMessageModel','TCPClient')
var tom = TOMMessageModel.alloc().initWithType_andMessageDic(1,{"data":"abc"})
console.log(tom)
tom.setDataDic({"data":"abcd"})
var data = tom.dataDic()
console.log(data)

var tcp = TCPClient.instance()
tcp.sendTomMessage_completion(tom,null)

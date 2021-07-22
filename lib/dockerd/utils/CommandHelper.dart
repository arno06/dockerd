import 'dart:io';
import 'package:dockerd/dockerd/utils/ConfigStorage.dart';

Future<ProcessResult> runDockerCommand(List<String> parameters){
  ConfigStorage config = ConfigStorage();
  List<String> params = new List<String>.from(config.dockerDefaultParameters);
  params.addAll(parameters);
  config.log(cmd: config.dockerCommand, parameters: params);
  return Process.run(config.dockerCommand, params, runInShell: true).then((ProcessResult results){
    if(results.exitCode != 0){
      //_log([], command:'Error : '+results.stderr);
      config.log(data: 'Error ('+results.exitCode.toString()+') : '+results.stderr);
    }
    return results;
  });
}

List<int> getCommandLineHeadLengths(String head, List<String> cols){
  List<int> lengths = [];
  var currIndex = 0;
  for(var i = 0, max = cols.length-1; i<max; i++){
    currIndex = head.indexOf(cols[i]);
    lengths.add(head.indexOf(cols[i+1]) - currIndex);
  }
  return lengths;
}

List<String> parseLine(String line, List<int> lengths){
  List<String> props = [];
  var currIndex = 0;
  for(var j = 0, maxj = lengths.length; j<maxj; j++){
    int end = (currIndex + lengths[j]).toInt();
    props.add(line.substring(currIndex, end).trim());
    currIndex = end;
  }
  props.add(line.substring(currIndex));
  return props;
}
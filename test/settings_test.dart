// to run this :!dart test test/kpl_test.dart --chain-stack-traces
import 'package:test/test.dart';
import 'package:nohfibu/settings.dart';

void main() {
  Settings regl = Settings();
  setUp(()
      {
      });
    test('Settings ', () {
      var incoming = ["-b", "phan.kpl", "-s", "-l" , "de", "--help", "-o","test.csv"];
      regl.init(incoming);

      expect(regl["help"], equals(true));
      expect(regl["base"], equals("phan"));
      expect(regl["type"], equals("wbstyle"));
      expect(regl["error"], equals(false));
      incoming = [];
      regl.init(incoming);
      expect(regl["help"], equals(false));
      expect(regl["base"], equals(null));
      expect(regl["type"], equals(null));
      incoming = ["-q", "phan.kpl", "-v", "-e" , "de", "--help", "-o","test.csv"];;
      regl.init(incoming);
      expect(regl["error"], equals(true));
    });



}

import 'package:flutter_test/flutter_test.dart';
import 'package:indigi_attendance/models/leave_model.dart';

void main() {
  test('LeaveBalance.fromJson parses correctly', () {
    final json = {
      "sl": 7,
      "cl": 6,
      "pl": 0,
      "cfl": 0,
      "el": 0,
      "hpl": 0,
      "ptl": 7,
      "mtl": 0,
      "mrl": 0,
      "brl": 3,
      "wfh": 24,
      "total": 29,
      "remaining": 23
    };

    final balance = LeaveBalance.fromJson(json);

    expect(balance.sickLeave, 7.0);
    expect(balance.casualLeave, 6.0);
    expect(balance.privilegeLeave, 0.0);
    expect(balance.carryForwardLeave, 0.0);
    expect(balance.earnedLeave, 0.0);
    expect(balance.happinessLeave, 0.0);
    expect(balance.paternityLeave, 7.0);
    expect(balance.maternityLeave, 0.0);
    expect(balance.marriageLeave, 0.0);
    expect(balance.bereavementLeave, 3.0);
    expect(balance.workFromHome, 24.0);
    expect(balance.total, 29.0);
    expect(balance.remaining, 23.0);
    expect(balance.isProbation, false);
    
    expect(balance.wfhDisplay, "24.0");
  });
}

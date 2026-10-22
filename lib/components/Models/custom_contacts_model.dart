import 'package:hive/hive.dart';
part 'custom_contacts_model.g.dart';

@HiveType(typeId: 4)
class CustomContactsModel {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? displayName;
  @HiveField(2)
  String? number;

  CustomContactsModel({this.id, this.displayName, this.number});

  CustomContactsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    displayName = json['displayName'];
    number = json['number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['displayName'] = displayName;
    data['number'] = number;
    return data;
  }
}

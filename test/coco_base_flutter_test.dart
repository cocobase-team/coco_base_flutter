import "package:coco_base_flutter/coco_base_flutter.dart";

void main() async {
  // Just a placeholder test file to ensure the package is working

  final config = CocobaseConfig(
    baseUrl: "http://127.0.0.1:8000",
    apiKey: "",
  );
  final db = Cocobase(config);

  final investmentCount = await db.listDocuments(
    "investment_batches",
    queryBuilder: QueryBuilder().where("status", "COMPLETED"),
  );

  print("Investment count: ${investmentCount[0].data}");
}

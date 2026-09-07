class APIResponse {
  bool success = false;
  String detail = "";
  dynamic id;
  dynamic items = [];
  int itemCount = 0;
  dynamic item;
  bool networkError = false;
  APIPaginationResponse? pagination;

  APIResponse({
    required this.success,
    required dynamic map,
    this.networkError = false,
  }) {
    fromJson(map);
  }

  void fromJson(dynamic map) {
    if (map is Map) {
      if (map["detail"] is List) {
        detail = map["detail"].toString();
      } else {
        detail = map["detail"]?.toString() ?? "No Response";
      }
      id = map["id"];
      items = map["items"] ?? [];
      itemCount = map["itemCount"] ?? 0;
      item = map["item"];
      pagination = map["pagination"] != null
          ? APIPaginationResponse.fromJson(map["pagination"])
          : null;
    } else {
      detail = "Invalid Response Format";
    }
  }

  static APIResponse fromJsonMap(dynamic map) {
    return APIResponse(
      success: map is Map ? (map["success"] ?? true) : false,
      map: map,
      networkError: map is Map ? (map["networkError"] ?? false) : false,
    );
  }

  @override
  String toString() {
    return '{success: $success, detail: $detail, id: $id, items: $items, itemCount: $itemCount, item: $item, networkError: $networkError}';
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "detail": detail,
      "id": id,
      "items": items,
      "itemCount": itemCount,
      "item": item,
      "networkError": networkError,
    };
  }
}

class APIPaginationResponse {
  int total = 0;
  int page = 0;
  int limit = 0;
  int pages = 0;
  int size = 0;
  String? nextCursor;
  String? prevCursor;

  APIPaginationResponse({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
    required this.size,
    this.nextCursor,
    this.prevCursor,
  });

  static APIPaginationResponse fromJson(dynamic map) {
    if (map is! Map) {
      return APIPaginationResponse(
        total: 0,
        page: 0,
        limit: 0,
        pages: 0,
        size: 0,
      );
    }
    return APIPaginationResponse(
      total: map["total"] ?? 0,
      page: map["page"] ?? 0,
      limit: map["limit"] ?? 0,
      pages: map["pages"] ?? 0,
      size: map["size"] ?? 0,
      nextCursor: map["next_cursor"],
      prevCursor: map["prev_cursor"],
    );
  }
}

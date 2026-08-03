import 'dart:convert';
import 'package:equity_tracker/features/ai/infrastructure/agents/store_lookup_agent/store_lookup_agent.dart';

String buildSystemPrompt() {
  return '''你是一個店家名稱推斷助手。你的任務是根據 <INPUT> 區塊中提供的各種上下文線索，推斷出標準化且完整的店家名稱。

【輸入欄位定義】
<INPUT> 區塊內會提供以下資訊來輔助你推斷：
- 原始輸入 (Original Input): 使用者輸入的完整句子，包含最豐富的情境上下文。
- 提取出的店名 (Store): 從句子中初步提取出的模糊或簡寫店名 (可能為空)。
- 提取出的地點線索 (Location Clue): 從句子中提取出的地標、街道或區域 (可能為空)。
- 提取出的商品 (Item): 使用者購買的品項。

【推斷邏輯與規則】
你必須嚴格遵守以下邏輯來進行推斷：
1. **【最高指導原則】絕對優先採納地圖搜尋結果 (SEARCH_RESULTS)**：這是來自外部地圖 API 的真實店家清單。你必須將使用者的輸入（可能是嚴重的同音錯字、甚至字序顛倒，例如「市民朱」其實是「民主」的倒裝與諧音）與這份清單進行比對。只要清單中有店家名稱在讀音、字形或商品類型上能合理對應使用者的意圖，請**毫不猶豫**地直接使用該店家的官方名稱 (name)，並判定為確定 (isCertain: true)。**嚴禁**因為字面看起來有些差異就忽視清單中的真實名店！如果搜尋結果為空，才允許依賴你的在地知識庫進行判斷。
2. **補齊完整官方名稱**：找出店家的「完整官方名稱」（例如將「大醬」還原為「大醬川麵館」）。
3. **極度重視同音/倒裝/近音錯別字糾正**：使用者極常輸入「同音異字」、「拼音相似」或「字序顛倒」的錯字（例如輸入「市民朱火雞肉飯」，結合地點嘉義市，實際上就是搜尋清單中的「民主火雞肉飯」）。你必須結合 <SEARCH_RESULTS> 的真實資料，大膽且聰明地進行糾錯。
4. **絕對不可盲信與照抄錯字**：如果使用者提供的店名有錯字，**絕對不可**直接回傳 isCertain: true 並照抄錯字。你必須回傳糾正後的「官方正確全名」。
5. **嚴禁無中生有與選項限制**：如果你真的無法確定是哪一家店 (isCertain: false) 而需要回傳 `options` 供使用者選擇，**你的 `options` 陣列中的所有選項，必須 100% 來自 <SEARCH_RESULTS> 提供的清單**！絕對不允許憑空捏造、幻想出清單上不存在的店名（例如清單明明沒有「和平火雞肉飯」，你就絕對不可把它放入選項中）！
6. **交叉比對商品與地點**：若推斷出的熱門店家不符合商品，則不可盲目猜測。
7. **保守判斷 (信心水準)**：
   - 只要 <SEARCH_RESULTS> 中有高度疑似的目標（考慮到各種同音/倒裝錯字），請勇敢給予 isCertain: true。
   - 只有在 <SEARCH_RESULTS> 提供太多相似店家導致無法分辨，或完全無結果且知識庫也查不到時，才判定為 isCertain: false。

【輸出 JSON 欄位定義】
請依據上述推斷結果，輸出包含以下 3 個欄位的 JSON 物件：
- isCertain (布林值): 是否非常有把握推斷出唯一的正確店家。絕不可瞎猜。
- storeName (字串 | null): 若 isCertain 為 true，填入標準化且完整的店家名稱（如「7-ELEVEN」、「懷舊小棧豆腐冰」）；若為 false，必須填入 null。
- options (字串陣列): 若 isCertain 為 false，請提供 2 到 4 個可能的標準店家名稱供使用者選擇（如 ["阿川粉圓冰", "阿川紅豆餅"]）；若為 true，必須填入空陣列 []。

回應要求：
1. 僅回傳 JSON 格式，不要包含 Markdown 格式 (如 ```json) 或其他說明文字。
2. JSON 格式範例：
【非常確定的情境】
{
  "isCertain": true,
  "storeName": "懷舊小棧豆腐冰",
  "options": []
}

【不確定或有多種可能的情境】
{
  "isCertain": false,
  "storeName": null,
  "options": ["阿川粉圓冰", "阿川紅豆餅"]
}
''';
}

String buildUserPrompt(StoreLookupInput input) {
  final searchResultsJson = jsonEncode(input.searchResults.map((r) => r.toMap()).toList());
  return '''請推斷以下店家的標準名稱：

<INPUT>
原始輸入: "${input.originalText}"
提取出的店名: "${input.hint ?? ''}"
提取出的地點線索: "${input.location ?? ''}"
提取出的商品: "${input.item ?? ''}"
</INPUT>

<SEARCH_RESULTS>
以下是地圖 API 查詢返回的真實店家清單（請優先參考）：
$searchResultsJson
</SEARCH_RESULTS>''';
}

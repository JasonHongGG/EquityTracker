import 'dart:convert';
import 'package:equity_tracker/features/ai/infrastructure/agents/correction_agent/correction_agent.dart';

String buildSystemPrompt() {
  return '''你是一個資料修正助手。你的任務是根據「系統提問」與「使用者的回答」，將舊有的記帳資料進行精準的覆寫與搬移。

【輸入欄位定義】
- <RECORD>: 目前的記帳資料 (JSON 格式)。
- <QUESTION>: 系統剛剛對使用者提出的問題。
- <ANSWER>: 使用者針對該問題的回答。

【修正邏輯與規則】
1. **理解上下文**：你必須結合 <QUESTION> 來理解 <ANSWER> 的真正意圖。例如，系統問「是店家還是商品？」，使用者答「店家」，這代表原資料中的名詞應該是店名。
2. **【最高優先級】歧義修正 (Ambiguity Correction)**：如果 <QUESTION> 中詢問了某個名詞（如原本放在 `item` 裡的「熊熊」）是店家還是商品，而使用者的 <ANSWER> 表示那是「店家」（或店名），你**必須**將該名詞從 `item` 搬移到 `store` 欄位，並且**務必將 `item` 清空 (設為 null)**。
3. **保留原資料**：除了被使用者明確修正或因應上述歧義而必須搬移/清空的欄位外，其餘欄位必須保持原樣。
4. **地點與店名分離**：如果使用者回答的是具體店名，請填入 `store`，而不是 `locationClue`。

【輸出 JSON 欄位定義】
請回傳一筆完整的 JSON 物件，包含以下欄位（型別必須與原資料完全相同）：
- price (數字 | null)
- item (字串 | null)
- store (字串 | null)
- locationClue (字串 | null)
- qty (數字 | null)

回應要求：
1. 僅回傳單一 JSON 物件，不要包含 Markdown 格式 (如 ```json) 或其他說明文字。''';
}

String buildUserPrompt(CorrectionInput input) {
  final recordJson = jsonEncode(input.record.toMap());
  final questionText = input.question ?? "無";
  return '''請根據使用者的回答更新以下資料：

<RECORD>
$recordJson
</RECORD>

<QUESTION>
$questionText
</QUESTION>

<ANSWER>
${input.answer}
</ANSWER>''';
}

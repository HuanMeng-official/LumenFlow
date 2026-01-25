param (
    [ValidateSet("zh", "en", "ja", "ko")]
    [string]$lang = "zh"
)

$UI = @{
    zh = @{
        Title = "LumenFlow角色卡生成器"
        EndHint = "请输入内容，输入 END 结束："

        RoleName = "角色名"
        RoleNameEN = "角色英文名 / 拼音"
        Identity = "角色身份描述"
        Philosophy = "角色核心哲学"
        OutputFile = "输出文件名（不含扩展名）"

        Personality = "【人格与心理逻辑】描述角色的性格结构、内在矛盾与行为动机（personality_logic）"
        Addressing  = "【称呼与称谓规则】角色在不同亲密度、情境下对用户的称呼方式（addressing_protocol）"
        Linguistic  = "【语言风格与表达习惯】包括语速、用词、潜台词与修辞偏好（linguistic_style）"
        Behavior    = "【行为叙事与非人特征规则】通过动作、感官、微表情体现角色特质（behavior_narrative_rules）"
        Interaction = "【互动策略与关系推进方式】角色如何影响、照顾并逐步绑定用户（interaction_strategy）"
        Example     = "【示例对话 / 场景演示】用于展示角色在实际互动中的语气与行为（example_dialogue）"

        Done = "角色卡生成完成："

        UserNameLabel   = "用户的名字"
        UserGenderLabel = "用户的性别"
    }

    en = @{
        Title = "LumenFlow Role Card Generator"
        EndHint = "Enter content. Type END to finish:"

        RoleName = "Character Name"
        RoleNameEN = "English Name / Romanization"
        Identity = "Character Identity / Background"
        Philosophy = "Core Philosophy"
        OutputFile = "Output file name (without extension)"

        Personality = "【Personality & Psychological Logic】Personality structure, conflicts, motivations (personality_logic)"
        Addressing  = "【Addressing Rules】How the character addresses the user (addressing_protocol)"
        Linguistic  = "【Linguistic Style】Speech rhythm, wording, subtext (linguistic_style)"
        Behavior    = "【Behavior & Non-human Traits】Actions, senses, micro-expressions (behavior_narrative_rules)"
        Interaction = "【Interaction Strategy】Bonding and influence methods (interaction_strategy)"
        Example     = "【Example Dialogue / Scene】Tone and behavior demonstration (example_dialogue)"

        Done = "Role card generated:"

        UserNameLabel   = "User Name"
        UserGenderLabel = "User Gender"
    }

    ja = @{
        Title = "LumenFlow キャラクターカード生成ツール"
        EndHint = "内容を入力してください。ENDで終了します："

        RoleName = "キャラクター名"
        RoleNameEN = "英語名／ローマ字"
        Identity = "キャラクター設定"
        Philosophy = "キャラクターの哲学"
        OutputFile = "出力ファイル名（拡張子なし）"

        Personality = "【人格・心理構造】性格構造と行動原理（personality_logic）"
        Addressing  = "【呼称ルール】状況別の呼び方（addressing_protocol）"
        Linguistic  = "【話し方・言語スタイル】語調・語彙（linguistic_style）"
        Behavior    = "【行動描写・非人特性】感覚と動作（behavior_narrative_rules）"
        Interaction = "【交流戦略】関係構築方法（interaction_strategy）"
        Example     = "【会話例／シーン】実際の振る舞い（example_dialogue）"

        Done = "キャラクターカード生成完了："

        UserNameLabel   = "ユーザー名"
        UserGenderLabel = "ユーザーの性別"
    }

    ko = @{
        Title = "LumenFlow 캐릭터 카드 생성기"
        EndHint = "내용을 입력하세요. END를 입력하면 종료됩니다:"

        RoleName = "캐릭터 이름"
        RoleNameEN = "영문 이름 / 로마자"
        Identity = "캐릭터 설정"
        Philosophy = "캐릭터 핵심 철학"
        OutputFile = "출력 파일 이름 (확장자 제외)"

        Personality = "【성격·심리 구조】성격과 행동 동기 (personality_logic)"
        Addressing  = "【호칭 규칙】상황별 사용자 호칭 (addressing_protocol)"
        Linguistic  = "【언어 스타일】말투·어휘 (linguistic_style)"
        Behavior    = "【행동·비인간 특성】감각과 동작 (behavior_narrative_rules)"
        Interaction = "【상호작용 전략】관계 형성 방식 (interaction_strategy)"
        Example     = "【대화 예시】실제 상호작용 (example_dialogue)"

        Done = "캐릭터 카드 생성 완료:"

        UserNameLabel   = "사용자 이름"
        UserGenderLabel = "사용자 성별"
    }
}

function Read-MultiLineInput {
    param ([string]$Prompt)

    Write-Host ""
    Write-Host $Prompt -ForegroundColor Yellow
    Write-Host $UI[$lang].EndHint -ForegroundColor DarkGray

    $lines = @()
    while ($true) {
        $line = Read-Host
        if ($line -eq "END") { break }
        $lines += $line
    }
    return ($lines -join "`n")
}

function Format-IndentedBlock {
    param (
        [string]$Text,
        [int]$IndentSpaces = 6
    )

    $indent = " " * $IndentSpaces
    return ($Text -split "`n" | ForEach-Object {
        if ($_.Trim() -eq "") { "" } else { "$indent$_" }
    }) -join "`n"
}

Write-Host $UI[$lang].Title -ForegroundColor Cyan

$RoleNameCN = Read-Host $UI[$lang].RoleName
$RoleNameEN = Read-Host $UI[$lang].RoleNameEN
$Identity   = Read-Host $UI[$lang].Identity
$Philosophy = Read-Host $UI[$lang].Philosophy

$PersonalityLogic = Format-IndentedBlock (Read-MultiLineInput $UI[$lang].Personality)
$Addressing      = Format-IndentedBlock (Read-MultiLineInput $UI[$lang].Addressing)
$LinguisticStyle = Format-IndentedBlock (Read-MultiLineInput $UI[$lang].Linguistic)
$BehaviorRules   = Format-IndentedBlock (Read-MultiLineInput $UI[$lang].Behavior)
$Interaction     = Format-IndentedBlock (Read-MultiLineInput $UI[$lang].Interaction)
$ExampleDialogue = Format-IndentedBlock (Read-MultiLineInput $UI[$lang].Example)

$FileName = Read-Host $UI[$lang].OutputFile
$OutputFile = "$FileName.xml"

$CharacterCard = @"
<system_instruction>
   <mate>
      <role_name>$RoleNameCN（$RoleNameEN）</role_name>
      <identity>$Identity</identity>
      <core_philosophy>$Philosophy</core_philosophy>
   </mate>

   <personality_logic>
$PersonalityLogic
   </personality_logic>

   <addressing_protocol>
$Addressing
   </addressing_protocol>

   <linguistic_style>
$LinguisticStyle
   </linguistic_style>

   <behavior_narrative_rules>
$BehaviorRules
   </behavior_narrative_rules>

   <interaction_strategy>
$Interaction
   </interaction_strategy>

   <user_info>
      - $($UI[$lang].UserNameLabel): `${userProfile.username}`
      - $($UI[$lang].UserGenderLabel): `${userProfile.gender}`
   </user_info>

   <example_dialogue>
$ExampleDialogue
   </example_dialogue>
</system_instruction>
"@

$CharacterCard | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host ""
Write-Host $UI[$lang].Done -ForegroundColor Green
Write-Host (Resolve-Path $OutputFile)

# Como adicionar perguntas e objetos

O jogo é em **primeira pessoa**: o jogador anda pelo laboratório
(`Scenes/Lab.tscn`), encontra objetos de termodinâmica e, ao olhar para eles e
apertar **F**, abre o **quiz** daquele objeto. Para "zerar" o jogo é preciso ser
**aprovado em todos os objetos**.

Cada objeto é uma **estação** (`Scenes/QuizStation.tscn`) ligada a um arquivo de
perguntas em `Data/`. O texto das perguntas fica no JSON; o resto é montado na
cena. Você **não precisa mexer no código** para adicionar conteúdo.

---

## 1. Formato do arquivo JSON

Cada objeto tem um arquivo em `Data/`, por exemplo `Data/bequer.json`:

```json
{
    "name": "Béquer",
    "questions": [
        {
            "q": "A que temperatura a água ferve ao nível do mar (1 atm)?",
            "options": [
                "0°C  (273 K)",
                "37°C  (310 K)",
                "100°C  (373 K)",
                "212°C  (485 K)"
            ],
            "correct": 2
        }
    ]
}
```

Regras:

- `name` — nome exibido no título do quiz.
- `questions` — lista; pode ter **quantas perguntas quiser**.
- Cada pergunta precisa de **exatamente 4 opções** em `options`.
- `correct` é o **índice da resposta certa começando do zero**:
  `0` = A, `1` = B, `2` = C, `3` = D.
- Use UTF-8 (acentos, °, ₂, ², ×, η etc. funcionam).

---

## 2. Adicionar uma pergunta a um objeto existente

1. Abra o arquivo do objeto em `Data/` (ex.: `Data/termometro.json`).
2. Adicione mais um bloco `{ "q": ..., "options": [...], "correct": ... }`
   dentro de `questions` (separe os blocos com vírgula).
3. Salve. A nova pergunta entra no quiz daquele objeto automaticamente.

---

## 3. Adicionar um objeto novo ao laboratório

### Passo 1 — Criar o arquivo de perguntas
Crie `Data/meu_objeto.json` no formato da seção 1.

### Passo 2 — Colocar a estação na cena
Abra `Scenes/Lab.tscn` no editor do Godot:

1. Selecione uma das estações existentes (`Station0` … `Station7`), clique com o
   botão direito → **Duplicate** (Ctrl+D). Surge uma `Station8`.
2. **Mova** a nova estação para onde quiser (arraste no editor ou ajuste a
   `Transform`). Coloque-a no chão, num lugar acessível.
3. No Inspector da estação, ajuste as 3 propriedades do script:
   - **Object Name** — o nome que aparece na mira/prompt e no título do quiz.
   - **Data File** — `res://Data/meu_objeto.json`.
   - **Tint** — a cor da caixa do objeto.
4. Salve e rode. A estação é registrada sozinha no progresso e entra na
   contagem "Concluídos: X/Y".

> Para **remover** um objeto, apague o nó `StationN` da cena (e, se quiser, o
> JSON em `Data/`).

---

## 4. Ajustar a nota mínima para "passar"

Abra `Scripts/GameProgress.gd` e mude a constante no topo:

```gdscript
const PASS_PERCENT: float = 0.6
```

É a fração mínima de acertos para ser aprovado em cada objeto.
Com 3 perguntas por objeto:
- `0.6` → aprova com **2 de 3** (permite 1 erro). *(padrão)*
- `0.7` → exige **3 de 3** (porque 2/3 = 0,667 < 0,7).

---

## 5. Onde fica cada coisa

| O quê | Onde |
|------|------|
| Texto das perguntas/opções | `Data/*.json` |
| Nome do objeto | `Object Name` da estação na cena (e `name` no JSON, p/ o título) |
| Cor do objeto | `Tint` da estação na cena |
| Quais objetos existem / posição | nós `StationN` em `Scenes/Lab.tscn` |
| Nota mínima de aprovação | `PASS_PERCENT` em `Scripts/GameProgress.gd` |
| Lógica do jogo (não precisa mexer) | `Scripts/Player.gd`, `Scripts/LabHUD.gd`, `Scripts/QuizStation.gd` |

---

## 6. Controles

| Ação | Comando |
|------|---------|
| Andar | W A S D |
| Olhar | Mouse |
| Interagir com o objeto na mira | F |
| Responder | Clique na opção (A/B/C/D) |
| Fechar o quiz / sair de telas | Esc |

# TermoQuiz — Documentação do Jogo

> Documento que explica **tudo** sobre o TermoQuiz: o que é, como funciona, como é
> a arquitetura, onde fica cada coisa e como rodar/editar. Gerado a partir da
> leitura do código e das cenas (jun/2026).
>
> ⚠️ **O `README.md` na raiz está DESATUALIZADO** — ele descreve um "FPS Stealth
> Prototype", que é o projeto-base do qual o TermoQuiz foi derivado. Para entender
> o jogo de verdade, use **este** documento.

---

## 1. O que é

**TermoQuiz** é um **jogo 3D educativo** feito em **Godot 4.6** (renderer
Forward+). O jogador anda em **primeira pessoa** por um laboratório de química e
interage com **8 estações** (equipamentos). Cada estação abre um **quiz de 5
perguntas** sobre **termoquímica e cinética química**. Para "zerar" o jogo é
preciso ser **aprovado em todas as 8 estações** (40 perguntas no total).

- **Plataforma-alvo:** desktop (Windows). Janela 1080×720.
- **Tema do conteúdo:** termoquímica e cinética química (entalpia, ΔH, reações
  endo/exotérmicas, velocidade de reação etc.). O banco de perguntas foi revisado
  a partir dos PDFs do professor.
- **Idioma:** Português (Brasil).
- **Público:** uso em sala de aula / estudo (estilo "escape room" de química).

---

## 2. Como se joga (loop principal)

1. O jogo começa na cena `Scenes/Lab.tscn`. O jogador nasce no corredor central
   olhando para os quadros/fórmulas na parede do fundo.
2. Anda pelo laboratório (**WASD** + **mouse**) e se aproxima das estações.
3. Ao mirar numa estação aparece o prompt **`[F] <nome do equipamento>`**.
   Pressionando **F**, abre o quiz daquele equipamento.
4. O quiz tem 5 perguntas de múltipla escolha (A/B/C/D). O jogador clica numa
   alternativa; o jogo mostra **na hora** se acertou (verde) ou errou (vermelho,
   já indicando a correta) e toca um som de acerto/erro.
5. No fim das 5 perguntas aparece a **tela de resultado** com:
   - Nota (X/5 e %), **APROVADO** ou **QUASE LÁ**;
   - Tempo total e número de erros;
   - Uma **tabela de avaliação** revisando cada questão (sua resposta × gabarito
     + tempo gasto naquela questão).
6. A estação fica **verde** quando aprovada (com comemoração: partículas, flash e
   pulo do anel). O contador no canto da tela mostra **`Concluídos: X / 8`**.
7. Quando **todas as 8** estão aprovadas, abre a **tela de vitória** ("Laboratório
   concluído") com **tempo total** e **erros** somados da sessão.

**Aprovação:** mínimo de **60% de acertos** por estação → com 5 perguntas, **3/5
acertos** já aprova (`PASS_PERCENT = 0.6` em `GameProgress.gd`).

---

## 3. Controles

| Ação | Comando |
|------|---------|
| Andar | **W A S D** (ou setas) |
| Olhar | **Mouse** |
| Interagir com a estação na mira | **F** |
| Responder uma pergunta | **Clique** na alternativa (A/B/C/D) |
| Fechar o quiz / sair de telas | **Esc** |

Detalhes:
- O mouse fica **capturado** (escondido) enquanto se explora; ao abrir um quiz ele
  é **liberado** para clicar nas alternativas, e o jogador fica **congelado**.
- A **mira** central cresce e fica colorida quando aponta para algo interagível.

---

## 4. Estações (os 8 equipamentos)

Cada estação tem um **nome**, um **arquivo de perguntas** em `Data/` e uma **cor**
(`tint`) que pinta a caixa, o anel de luz e os destaques do quiz. Configuradas em
`Scenes/Lab.tscn` (nós `Station0`…`Station7`, script `Scripts/QuizStation.gd`).

| # | Equipamento | Arquivo de perguntas | Cor (tint) |
|---|-------------|----------------------|------------|
| 0 | Bico de Bunsen | `Data/bico_de_bunsen.json` | laranja |
| 1 | Béquer | `Data/bequer.json` | azul |
| 2 | Termômetro | `Data/termometro.json` | vermelho |
| 3 | Pistão / Cilindro | `Data/pistao_cilindro.json` | cinza (padrão) |
| 4 | Calorímetro | `Data/calorimetro.json` | âmbar/dourado |
| 5 | Manômetro | `Data/manometro.json` | verde |
| 6 | Condensador | `Data/condensador.json` | ciano |
| 7 | Máquina Térmica | `Data/maquina_termica.json` | roxo |

Cada arquivo tem **5 perguntas** → **40 perguntas** no total.

---

## 5. Formato das perguntas (JSON)

Cada equipamento aponta para um arquivo em `Data/`. Exemplo real
(`Data/calorimetro.json`):

```json
{
    "name": "Calorímetro",
    "questions": [
        {
            "q": "Os reagentes têm entalpia de 500 kJ e os produtos 200 kJ. Qual é o ΔH da reação?",
            "options": ["+300 kJ", "-300 kJ", "+700 kJ", "-700 kJ"],
            "correct": 1
        }
    ]
}
```

Regras:
- `name` — título exibido no topo do quiz.
- `questions` — lista de perguntas (pode ter quantas quiser).
- Cada pergunta precisa de **exatamente 4 opções** em `options`.
- `correct` — **índice da resposta certa começando do zero**: `0` = A, `1` = B,
  `2` = C, `3` = D.
- Arquivos em **UTF-8** (acentos e símbolos como `Δ`, `°`, `₂`, `→`, `η` funcionam).

**Embaralhamento:** a cada vez que se abre o quiz, a **ordem das perguntas** e a
**posição das alternativas** são embaralhadas (o índice correto é recalculado
automaticamente). Então não dá para "decorar a letra".

---

## 6. Arquitetura / como o código funciona

### Cena principal
`Scenes/Lab.tscn` — a sala do laboratório. Contém:
- O **Player** (`Scenes/Player.tscn`).
- A **HUD** (canvas com a interface).
- As **8 estações** (`Scenes/QuizStation.tscn`).
- O nó **LabDecor** (espalha props de laboratório em runtime).
- Geometria da sala (paredes, piso, bancadas, quadros) e iluminação.

### Scripts (`Scripts/`)

| Script | Papel |
|--------|-------|
| **`GameProgress.gd`** | **Autoload** (singleton global). Guarda o progresso: quais estações foram registradas/aprovadas, e estatísticas (tempo, erros) por estação. Emite os sinais `updated` e `completed`. |
| **`Player.gd`** | `CharacterBody3D` em primeira pessoa: movimento WASD + mouse-look, gravidade, e o **raycast** que detecta a estação mirada para mostrar o prompt e chamar `F` → interagir. |
| **`QuizStation.gd`** | `StaticBody3D` de cada equipamento. Cria seus materiais/luzes, faz o ícone flutuar e **pulsar** quando não concluído, fica **verde** quando aprovado, e ao interagir chama `hud.open_quiz(...)`. |
| **`LabHUD.gd`** | `CanvasLayer`. Constрói **toda a interface por código** (mira, contador, barra de progresso, painel do quiz, tela de vitória), carrega o JSON, conduz o fluxo do quiz, monta a tabela de avaliação e toca os áudios. É o coração da UI. |
| **`LabDecor.gd`** | Espalha props (vidrarias, cadeiras, geladeira, lixeira) em runtime, extraindo peças do kit GLB `Models/low_poly_laboratory_assets.glb`. |
| **`_shot.gd`** | Utilitário de screenshots de conferência. Só age quando rodado com `-- --shots`; em jogo normal é inerte. |

### Fluxo de uma rodada de quiz (resumo técnico)

1. `Player._try_interact()` dispara o raycast; se acertar um nó do grupo
   `Interactable`, chama `obj._interact()`.
2. `QuizStation._interact()` → `LabHUD.open_quiz(data_file, objectName, tint)`.
3. `LabHUD` carrega o JSON, embaralha perguntas/opções, libera o mouse e mostra o
   painel.
4. A cada resposta, registra acerto/erro, tempo da questão e a alternativa marcada
   (para a tabela de revisão).
5. No fim, chama `GameProgress.set_result(...)` e `GameProgress.record_stats(...)`.
6. `GameProgress` emite `updated` (atualiza contador/cor da estação) e, se tudo foi
   aprovado, `completed` (dispara a tela de vitória).

**Importante:** o progresso vive só em memória (não há save em disco). Reiniciar o
jogo zera tudo; a tela de vitória tem botão **RECOMEÇAR** que chama
`GameProgress.reset()`.

---

## 7. Estrutura de pastas

```
TermoQuiz/
├─ project.godot              # configuração do projeto (autoload, input, etc.)
├─ Scenes/
│  ├─ Lab.tscn                # ★ cena principal (o laboratório)
│  ├─ Player.tscn             # jogador em primeira pessoa
│  └─ QuizStation.tscn        # uma estação de quiz (reusada 8×)
├─ Scripts/
│  ├─ GameProgress.gd         # autoload de progresso
│  ├─ Player.gd, QuizStation.gd, LabHUD.gd, LabDecor.gd, _shot.gd
├─ Data/                      # ★ as 8 perguntas em JSON (uma por equipamento)
│  ├─ bico_de_bunsen.json, bequer.json, termometro.json, ...
├─ Models/                    # modelos 3D (.glb): kit de laboratório, mesa, planta
├─ Textures/                  # texturas
├─ Fonts/                     # Oswald (texto) e IBM Plex Mono (HUD/console)
├─ Audios/                    # bgmusic.mp3, right.mp3, wrong.mp3
├─ Sounds/                    # áudios diversos
├─ _shots/                    # screenshots geradas pelo utilitário _shot.gd
├─ COMO_ADICIONAR_CONTEUDO.md # guia para editar perguntas/objetos
├─ SOBRE_O_JOGO.md            # ← este arquivo
└─ README.md                  # ⚠️ desatualizado (descreve o projeto-base)
```

---

## 8. Como editar conteúdo (resumo)

> Guia completo em [`COMO_ADICIONAR_CONTEUDO.md`](COMO_ADICIONAR_CONTEUDO.md).

- **Mudar/adicionar perguntas:** edite o JSON em `Data/` (formato da seção 5). Não
  precisa mexer no código.
- **Adicionar um equipamento novo:** crie `Data/meu_objeto.json`, depois no editor
  do Godot duplique uma `StationN` em `Scenes/Lab.tscn`, posicione, e ajuste no
  Inspector: **Object Name**, **Data File** (`res://Data/meu_objeto.json`) e
  **Tint**. Ela entra sozinha na contagem.
- **Mudar a nota mínima:** constante `PASS_PERCENT` em `Scripts/GameProgress.gd`
  (`0.6` = 60%).

---

## 9. Como rodar

**No editor:** abra a pasta do projeto no Godot 4.6 e dê **Play** (F5). A cena
principal já é `Scenes/Lab.tscn`.

**Validar mudanças sem abrir o editor** (headless — carrega autoloads + cena e roda
alguns frames; bom para checar erros de script/cena). Exemplo em PowerShell:

```powershell
$exe="C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
Start-Process $exe -ArgumentList @("--headless","--quit-after","120") `
  -WorkingDirectory (Get-Location) -RedirectStandardError "$env:TEMP\g.err" `
  -NoNewWindow -PassThru -Wait | Out-Null
Get-Content "$env:TEMP\g.err"
```

Sai com código 0 e **sem `SCRIPT ERROR` / `Parse Error`** = cenas e scripts OK.
(As linhas `ObjectDB instances leaked at exit` e `1 resources still in use at exit`
são **normais** ao encerrar headless e não indicam problema.)

Observações:
- O quiz só lê o JSON na **interação (tecla F)**, que não roda em headless — para
  validar um JSON à parte: `Get-Content x.json -Raw | ConvertFrom-Json`.
- Para **renderizar/screenshot** de verdade, rode **sem** `--headless` (precisa de
  display/Vulkan).

---

## 10. Detalhes de apresentação

- **Visual:** estações com pedestal, anel luminoso, feixe holográfico e ícone
  flutuante que **pulsa** enquanto não concluído e fica **verde estável** ao ser
  aprovado.
- **HUD diegética:** painel estilo "console de laboratório" (escuro), recolorido
  com a cor do equipamento atual; fontes Oswald + IBM Plex Mono.
- **Feedback:** som de acerto/erro, animações (pop, shake na alternativa errada,
  confete na aprovação) e tabela de revisão pós-quiz.
- **Áudio:** música de fundo em loop bem baixa + efeitos de acerto/erro.

---

### Resumo de uma linha

Um **walking-sim educativo de química**: ande pelo laboratório, responda o quiz de
cada um dos 8 equipamentos, acerte ≥60% em todos e veja a tela de vitória com seu
tempo e erros.

---

*Engine: Godot 4.6 (Forward+) · Linguagem: GDScript · Conteúdo: termoquímica e cinética química.*

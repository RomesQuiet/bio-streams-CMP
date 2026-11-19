# Plasticine Tamagotchi: interface specification v1 (copy)

> Copy of the team's document `plasticTamagotchi01.rtf` (18 Nov 2026), kept as written (European Portuguese). It is the rule for the interface since Milestone 25 (`MILESTONE_25.md`), with the user's answers recorded there. The approved mockups are in `documentation/ui_mockups/`.

Especificação de interface gráfica, HUD e ciclo dia/noite
Instruções para implementação por uma IA de programação
## 1. Objectivo
Redesenhar a interface gráfica do jogo Plasticine Tamagotchi, utilizando como referência principal os mockups finais aprovados.
A interface deve ser construída, tanto quanto possível, com geometria vectorial produzida por código, utilizando linhas, contornos (strokes), polígonos, curvas, gradientes, preenchimentos, transparências e texto.
Não se pretende simplesmente colocar as imagens dos mockups como fundos ou reproduzir a interface através de dezenas de sprites.
O objectivo é recriar um sistema gráfico dinâmico, responsivo, parametrizável e reutilizável.
O ecrã principal constitui a referência visual para todos os restantes ecrãs e minijogos.
A implementação deve integrar-se no projecto existente, preservando a lógica, as funcionalidades, os dados e a navegação já desenvolvidos.

## 2. Linguagem gráfica geral
A interface utiliza um estilo de videojogo 2D contemporâneo, com características de ilustração vectorial e banda desenhada.
Princípios:
- Formas geométricas simples, sobretudo rectângulos arredondados, círculos e curvas.
- Contornos bem definidos e consistentes.
- Cores vivas, mas equilibradas.
- Transparências discretas.
- Gradientes suaves.
- Botões coloridos com ligeira espessura e reacção táctil.
- HUD minimalista, sem aspecto tridimensional.
- Tipografia sans-serif arredondada, clara e muito legível.
- Balões de fala brancos, com contorno escuro, semelhantes aos utilizados na banda desenhada.
- Fundo atmosférico abstracto, com céu e solo curvo.
Distinção fundamental: os botões devem parecer pressionáveis, enquanto o HUD e os elementos informativos devem parecer superfícies planas, sem qualquer sugestão de interacção.
Evitar bevels, brilhos artificiais, sombras fortes ou elementos excessivamente volumétricos no HUD.

## 3. Organização geral do ecrã principal
O ecrã tem formato vertical, em proporções típicas de um smartphone.
A disposição deve preservar as seguintes zonas:
1. HUD: junto ao bordo superior, ocupando praticamente toda a largura.
2. Relógio e Pause: imediatamente abaixo do HUD, rigorosamente centrados horizontalmente.
3. Settings: uma pequena roda dentada branca, à direita, sem fundo próprio.
4. Balão de fala: na zona superior/intermédia, acima da personagem.
5. Personagem: centrada horizontalmente, sobre o solo curvo.
6. Controlos principais: quatro botões grandes, dispostos numa quadrícula 2×2, junto à zona inferior.
A interface deve adaptar-se a diferentes resoluções de telemóvel sem perder estas relações espaciais.
É importante manter alguma margem entre os quatro botões, mas sem os separar excessivamente.

## 4. HUD: Health e XP
### 4.1. Geometria do HUD
O HUD consiste num único rectângulo arredondado, com:
- Contorno branco fino, aproximadamente 1–2 px na resolução de referência, escalado proporcionalmente.
- Preenchimento branco com cerca de 5% de opacidade.
- Sem bevel.
- Sem sombra.
- Sem brilho artificial.
- Cantos bem arredondados.
- Duas divisórias verticais finas.
O HUD deve ficar muito próximo do topo, respeitando apenas a safe area do dispositivo.
Organização horizontal:
[Health] | [XP] | [XP Level]
A zona Health é a principal. As outras duas representam a progressão por experiência.
### 4.2. Health
A parte esquerda do HUD apresenta:
- Um coração vermelho.
- A palavra Health.
- O valor numérico actual, imediatamente à direita da palavra, por exemplo Health 3.
- Uma barra com exactamente cinco pastilhas arredondadas.
O número indica o nível de saúde actual numa escala de 1 a 5.
Funcionamento das cinco pastilhas
As cinco pastilhas não devem funcionar apenas como cinco indicadores binários, preenchidos ou vazios.
Devem funcionar como uma máscara visual sobre uma única barra contínua.
Por exemplo:
- Health 1.0: uma pastilha completamente preenchida.
- Health 2.0: duas pastilhas preenchidas.
- Health 2.5: duas pastilhas e metade da terceira.
- Health 3.7: três pastilhas e 70% da quarta.
- Health 5.0: todas as pastilhas preenchidas.
A parte activa é vermelha, podendo utilizar um gradiente vermelho muito subtil.
A parte inactiva é azul-acinzentada translúcida.
O preenchimento é contínuo entre as pastilhas. Os intervalos entre elas são apenas uma máscara gráfica e não interrupções no valor da barra.
O preenchimento parcial de uma pastilha é importante para mostrar que a saúde evolui de modo gradual.
Número Health
O valor numérico deve estar sincronizado com o estado de saúde real.
Nos mockups utiliza-se Health 3, mas a implementação deve prever valores decimais internos. Pode apresentar-se o valor inteiro arredondado ou uma casa decimal quando necessário, desde que o comportamento seja consistente.
Não escrever Health Lv. nem Health Level no HUD final.
A designação aprovada é simplesmente Health 3, ou o valor correspondente.
O indicador gráfico não deve contradizer o valor numérico.

### 4.3. XP
A zona central apresenta:
XP 70 / 100
Por baixo encontra-se uma barra horizontal de progresso.
Características:
- Barra de fundo azul-acinzentado translúcido.
- Preenchimento azul-ciano.
- Cantos arredondados.
- Gradiente muito subtil, se necessário.
- Actualização dinâmica do preenchimento.
A barra representa o progresso dentro do nível de experiência actual.
Por exemplo, XP 70 / 100 corresponde a um preenchimento de 70%.
O XP e o Health são dois sistemas distintos. A saúde reflecte o estado físico e os hábitos da personagem. O XP representa a progressão do jogador.
Não alterar as regras de aquisição de XP existentes no jogo sem necessidade.

### 4.4. XP Level
A terceira zona apresenta o título:
XP Level
Por baixo mostra-se o nível actual e o próximo nível.
Exemplo:
2 → 3
Hierarquia visual:
- O 2 é grande, branco e perfeitamente visível.
- A seta é discreta.
- O 3 é mais pequeno e parcialmente transparente, aproximadamente 45–60% de opacidade.
O 3 representa o próximo nível, ainda não alcançado.
Não utilizar um anel circular em torno do número, nem um contador volumétrico.
Este componente deve ser minimalista e relacionar-se visualmente com a barra de XP.
Evolução de nível
Quando o XP atinge 100:
1. A barra XP chega a 100%.
2. Pode surgir uma animação breve e discreta de Level Up!.
3. O nível actual aumenta uma unidade.
4. O próximo nível também aumenta uma unidade.
5. A barra XP regressa a zero e começa a preencher novamente.
Exemplo:
Antes: XP 98/100 | XP Level 2 → 3
No limite: XP 100/100 | XP Level 2 → 3
Depois: XP 0/100 | XP Level 3 → 4
Se o jogador ganhar XP suficiente para ultrapassar 100, o excesso deve ser conservado e aplicado ao nível seguinte. A lógica deve igualmente suportar a passagem de mais de um nível numa única actualização.
Pode animar-se a substituição dos números, com uma pequena translação vertical, como um contador rotativo, mas sem introduzir uma nova moldura ou elemento volumétrico.

## 5. Relógio e Pause
O relógio e o botão Pause constituem um único componente, centrado horizontalmente.
Exemplo:
10:15 PM | Ⅱ
Características:
- Forma de cápsula horizontal.
- Contorno branco fino.
- Fundo branco com cerca de 5% de opacidade.
- Sem bevel.
- Sem sombra.
- Texto branco.
- Separador vertical entre a hora e o Pause.
- Símbolo Pause branco.
- Tipografia de leitura imediata.
A hora utiliza o formato de 12 horas, com AM e PM.
O botão Pause é clicável. A hora é apenas informativa.
Ao activar Pause, o tempo simulado e as restantes actividades temporizadas devem comportar-se de acordo com a lógica de pausa existente no jogo.
Não criar uma segunda fonte de tempo independente: o relógio deve usar o mesmo estado temporal que controla as mecânicas e o ambiente.

## 6. Settings
O botão Settings deve ser extremamente discreto.
Deve consistir apenas numa roda dentada branca, sem:
- Fundo.
- Rectângulo ou círculo de suporte visível.
- Contorno exterior adicional.
- Sombra.
- Gradiente.
Deve ficar à direita, aproximadamente alinhado com o relógio.
Embora o desenho seja pequeno, a área clicável pode ser maior e invisível, garantindo uma boa experiência em dispositivos tácteis.

## 7. Fundo dinâmico: ciclo de 24 horas
Este é um dos elementos visuais mais importantes do projecto.
O fundo deve evoluir continuamente ao longo do dia e da noite, acompanhando o relógio interno do jogo.
Não utilizar uma sequência de imagens estáticas para simular as horas do dia.
Criar o ambiente através de gradientes, formas vectoriais e interpolação de parâmetros.
### 7.1. Componentes do fundo
O cenário deve conter:
1. Céu com gradiente de cores.
2. Sol.
3. Lua.
4. Estrelas nocturnas.
5. Solo curvo.
6. Opcionalmente, pequenas nuvens geométricas muito discretas.
O céu deve ser abstracto.
Não introduzir árvores, edifícios, montanhas detalhadas, paisagens realistas ou texturas complexas.
### 7.2. Solo curvo
Na zona inferior/intermédia existe uma superfície curva, sugerindo subtilmente a curvatura do globo terrestre.
Pode ser representada por uma curva Bézier ou pela parte superior de uma elipse suficientemente grande.
A personagem deve parecer estar apoiada nessa superfície.
O solo ocupa a parte inferior do ambiente, por detrás da personagem e dos botões.
A cor do solo deve evoluir com a iluminação do céu, embora se mantenha distinguível do fundo.
De dia poderá ter tons azulados ou turquesa.
Ao pôr-do-sol poderá adquirir tonalidades violetas.
À noite deverá ser azul-escuro.
A transição de cor deve ser contínua.

### 7.3. Movimento do Sol
O Sol nasce à esquerda do ecrã, sobe progressivamente, passa pela zona superior do céu ao meio-dia e desce até desaparecer à direita.
O seu movimento deve seguir um arco contínuo.
Para um primeiro modelo, utilizar:
- Nascer do Sol: 06:00.
- Meio-dia solar: 12:00.
- Pôr-do-sol: 18:00 ou 19:00, consoante a configuração adoptada.
Estas horas podem ser configuráveis e não precisam de corresponder a uma localização geográfica real.
Posições exemplificativas
Hora
Posição do Sol
06:00
Horizonte esquerdo
07:30
Esquerda, baixo
09:00
Esquerda, intermédio
12:00
Centro, posição mais elevada
15:00
Direita, intermédio
17:30
Direita, baixo
19:00
Horizonte direito
A regra é fundamental:
Antes do meio-dia o Sol fica à esquerda. Depois do meio-dia fica à direita.
A posição não pode ser aleatória nem definida por imagens independentes.
Cálculo geométrico
Uma possibilidade é utilizar uma parametrização do semicírculo:
t = (hora - nascer_sol) / (por_sol - nascer_sol)

angle = PI * t

x = center_x - radius_x * cos(angle)
y = horizon_y - radius_y * sin(angle)
Com t entre 0 e 1.
A parametrização exacta poderá ser adaptada para assegurar o enquadramento visual e as dimensões disponíveis.
O Sol deve ser um círculo simples, de cor amarelo-claro ou creme, podendo ter um brilho radial muito subtil.
Não são necessários sprites.

### 7.4. Movimento da Lua
Durante a noite, a Lua deve percorrer igualmente um arco.
Surge na parte esquerda do céu após o pôr-do-sol, sobe durante a noite e desce para a direita antes do amanhecer.
A trajectória deve ser contínua através da meia-noite.
A Lua pode ser desenhada através de duas formas circulares sobrepostas, produzindo uma Lua crescente por subtracção ou máscara.
Utilizar uma tonalidade creme muito clara.
O tamanho e a linguagem gráfica devem ser compatíveis com o Sol.
Não utilizar imagens fotográficas da Lua.

### 7.5. Estrelas
As estrelas devem aparecer progressivamente à medida que escurece e desaparecer durante o amanhecer.
Devem ser apenas pequenos pontos brancos, preferencialmente círculos de diferentes dimensões muito reduzidas.
Evitar estrelas com quatro ou cinco pontas, brilhos elaborados ou efeitos excessivos.
Distribuir os pontos por coordenadas pseudo-aleatórias fixas.
As posições devem ser estáveis, sem saltos ou mudanças aleatórias a cada frame.
A opacidade das estrelas deve ser controlada pela luminosidade do céu.

### 7.6. Gradientes do céu
O céu deve mudar progressivamente ao longo das 24 horas.
Exemplos de estados:
Hora
Aspecto
06:00
Rosa, lilás e azul suave
09:00
Azul-claro e ciano
12:00
Azul vivo, luminoso
16:30
Azul suave com tons quentes
19:15
Laranja, rosa, violeta
22:15
Azul profundo e violeta escuro
Estas cores são orientativas. Os valores RGB ou hexadecimais definitivos devem ser definidos para reproduzir os mockups aprovados.
Não fazer mudanças abruptas entre cores.
Criar uma tabela de color stops, cada uma associada a uma hora, e interpolar continuamente entre elas.
Preferencialmente, utilizar mais de uma cor por hora, permitindo gradientes verticais ou radiais.
O pôr-do-sol deve apresentar maior luminosidade perto do horizonte.
A noite deve manter alguma variação cromática e não ser uma superfície preta uniforme.
Todo o ambiente deve poder ser actualizado a partir de uma única variável:
game_time
Se o relógio avançar, o céu, o Sol, a Lua, as estrelas e o solo devem actualizar-se de modo sincronizado.

## 8. Personagem
A personagem é o elemento central do jogo.
Deve manter-se centrada horizontalmente e apoiada no solo curvo.
As suas expressões e animações representam o estado de saúde, cansaço, felicidade e outras condições do jogo.
O sistema gráfico da interface deve funcionar independentemente da tecnologia utilizada para representar a personagem.
Não substituir os modelos ou as animações existentes sem necessidade.
A personagem poderá continuar a utilizar os recursos gráficos existentes, enquanto o fundo, o HUD e os controlos são desenhados por código.
As expressões apresentadas nos mockups são referências visuais, não uma obrigação de substituir a personagem actual.

## 9. Balões de fala
Os balões de fala são elementos de comunicação contextual.
Devem aproximar-se da linguagem da banda desenhada.
Aparência
- Fundo branco.
- Contorno azul-marinho escuro.
- Forma arredondada, ligeiramente oval ou rectangular com cantos muito arredondados.
- Pequena ponta triangular ou curva dirigida para a personagem.
- Texto azul-marinho escuro.
- Ícone contextual opcional.
- Sem sombra.
- Sem bevel.
Evitar balões quadrados ou caixas genéricas de notificação.
O balão deve ter dimensão suficiente para mostrar a mensagem confortavelmente, sem ocupar uma área excessiva do ecrã.
Conteúdo dinâmico
As mensagens reflectem o estado actual da personagem.
Exemplos:
Cansaço: "I'm tired. Sleep is recommended."
Alimentação: "Time to eat! You'll regain energy."
Exercício: "A bit of exercise would be great now!"
Descanso nocturno: "Time to rest! A good night's sleep improves your health."
O ícone deve corresponder à mensagem: cama, maçã, corrida, etc.
As mensagens devem ser escolhidas com base nas regras existentes do jogo.
Não associar automaticamente uma recomendação de dormir a todas as horas nocturnas, nem uma recomendação de comer a todas as horas do almoço, se o estado real da personagem não justificar essa recomendação.
O sistema deve permitir localização para outras línguas, preservando o mecanismo de tradução utilizado no projecto.

## 10. Botões principais
Manter exactamente quatro botões, em quadrícula 2×2:
Esquerda
Direita
Exercise
Sleep
Eat
Entertainment
Utilizar o estilo aprovado, com cores pastel vivas, contornos claros e ligeiro relevo.
Cores aproximadas:
- Exercise: turquesa/menta.
- Sleep: lavanda/lilás.
- Eat: rosa-salmão.
- Entertainment: amarelo-dourado.
Cada botão tem um ícone por cima do texto.
Ícones:
- Exercise: figura humana a correr.
- Sleep: cama com pequenos Z.
- Eat: maçã.
- Entertainment: comando de videojogos.
Os ícones devem, sempre que viável, ser desenhados como caminhos vectoriais, primitivas geométricas ou elementos de uma biblioteca de ícones vectoriais.
Os botões não devem ser excessivamente ornamentados.
Geometria
- Rectângulos arredondados.
- Cantos pronunciadamente arredondados.
- Contorno fino claro.
- Preenchimento com gradiente vertical muito subtil.
- Faixa inferior ligeiramente mais escura, sugerindo a espessura do botão.
- Sombra curta e discreta.
O espaçamento horizontal e vertical deve ser ligeiramente superior ao dos primeiros mockups, garantindo que cada botão é percebido como um elemento independente.
Não aumentar demasiado os intervalos.
Estado normal
O botão apresenta o corpo principal, a espessura inferior e uma sombra curta.
Estado pressionado
Este estado é especialmente importante.
O botão deve deslocar-se visivelmente para baixo, simulando uma pressão física.
Ao pressionar:
1. O corpo do botão desce aproximadamente 6–8 px na resolução de referência, com escala responsiva.
2. A espessura inferior diminui.
3. A sombra diminui ou desaparece.
4. O preenchimento pode ficar ligeiramente mais escuro.
5. O botão regressa suavemente à posição inicial quando a pressão termina.
Não basta mudar a cor ou acrescentar um contorno luminoso.
A deslocação e a compressão devem transmitir uma reacção táctil convincente.
Implementar também um estado desactivado com menor saturação e opacidade, preservando a legibilidade.

## 11. Interface responsiva
A composição deve adaptar-se a smartphones com diferentes dimensões e proporções.
Utilizar como referência o formato portrait dos mockups.
Requisitos:
- HUD ancorado ao topo.
- Relógio centrado.
- Settings ancorado à direita.
- Personagem centrada.
- Botões ancorados à zona inferior.
- Balão de fala posicionado em relação à personagem e ao espaço disponível.
- Respeito pelas safe areas do dispositivo.
- Dimensões mínimas adequadas a interacção táctil.
- Nenhum texto cortado ou sobreposto.
Os elementos devem ser escalados de modo coerente.
Sempre que possível, utilizar coordenadas normalizadas, anchors e containers, evitando posições absolutas rígidas.
A posição do Sol e da Lua deve ser calculada em relação à área útil do céu, não em relação a coordenadas fixas de uma imagem.

## 12. Requisitos técnicos
Antes de implementar, analisar a estrutura do projecto existente, especialmente:
- Motor e versão utilizados.
- Organização de cenas.
- Sistema de UI.
- Gestão de estado.
- Relógio interno.
- Sistema de Health.
- Sistema de XP e níveis.
- Recursos gráficos da personagem.
- Sistema de tradução.
- Navegação entre ecrãs.
Se o projecto estiver em Godot, privilegiar recursos nativos do motor, incluindo:
- Control para os elementos de UI.
- CanvasItem e desenho personalizado com _draw() para primitivas vectoriais.
- draw_rect, draw_line, draw_circle, draw_polygon e funções de desenho equivalentes.
- ShaderMaterial para gradientes e efeitos atmosféricos quando apropriado.
- Tween ou AnimationPlayer para animações dos botões, progressões e transições.
- Temas e estilos reutilizáveis.
- Anchors e containers para o posicionamento responsivo.
Estas são sugestões de implementação, não uma obrigação de reestruturar o projecto.
Não é necessário desenhar todos os elementos com um único método. Por exemplo, labels podem utilizar componentes de texto nativos, e gradientes complexos podem utilizar shaders.
A prioridade é obter gráficos nítidos, leves, parametrizáveis e coerentes.
Evitar
- Importar o mockup inteiro como uma imagem.
- Criar 24 fundos diferentes para as horas do dia.
- Criar sprites separados para cada nível de Health.
- Criar sprites separados para cada valor de XP.
- Criar imagens individuais para os estados dos botões.
- Recriar a lógica do jogo quando já existe uma implementação funcional.
- Utilizar efeitos de iluminação pesados sem necessidade.
A interface deve funcionar com bom desempenho em telemóveis Android e iOS.

## 13. Arquitectura recomendada
Separar os elementos visuais em componentes reutilizáveis.
Uma organização possível:
GameScreen
│
├── DynamicBackground
│   ├── SkyGradient
│   ├── Sun
│   ├── Moon
│   ├── Stars
│   └── CurvedGround
│
├── HUD
│   ├── HealthDisplay
│   │   ├── Heart
│   │   ├── HealthValue
│   │   └── FivePillHealthBar
│   │
│   ├── XPProgress
│   │   ├── XPValue
│   │   └── XPBar
│   │
│   └── XPLevelDisplay
│       ├── CurrentLevel
│       ├── Arrow
│       └── NextLevel
│
├── ClockPause
│   ├── GameClock
│   └── PauseControl
│
├── SettingsControl
│
├── Character
│
├── SpeechBalloon
│
└── ActionButtons
    ├── ExerciseButton
    ├── SleepButton
    ├── EatButton
    └── EntertainmentButton
O sistema deve separar claramente os dados do jogo da sua representação visual.
Por exemplo, um valor de Health pode ser emitido por um gestor de estado e recebido pelo componente HealthDisplay, que actualiza o número e a barra.
O mesmo princípio aplica-se ao XP, ao relógio e às mensagens contextuais.

## 14. Sistema visual comum aos restantes ecrãs
Este é o ecrã base do jogo e deve definir a identidade gráfica de toda a aplicação.
Os restantes ecrãs, menus e minijogos devem seguir a mesma linguagem visual.
Isso não significa utilizar exactamente a mesma composição em todos os ecrãs.
Significa conservar:
- Paleta cromática coerente.
- Tipografia.
- Espessuras de contorno.
- Raios de arredondamento.
- Estilo de ícones.
- Botões com resposta táctil.
- Balões de fala em estilo de banda desenhada.
- HUD e indicadores de progresso planos e discretos.
- Tratamento de transparências.
- Gradientes suaves.
- Distinção clara entre elementos informativos e interactivos.
Os minijogos podem ter controlos próprios, incluindo gamepads e painéis contextuais, mas esses controlos devem utilizar as mesmas regras de cor, contorno e feedback.
Criar um pequeno conjunto de constantes ou tokens de design para assegurar essa consistência.
Por exemplo:
UI_BORDER_THIN
UI_BORDER_MEDIUM
UI_CORNER_RADIUS
UI_HUD_OPACITY
UI_TEXT_PRIMARY
UI_TEXT_SECONDARY
UI_HEALTH_COLOR
UI_XP_COLOR
UI_EXERCISE_COLOR
UI_SLEEP_COLOR
UI_EAT_COLOR
UI_ENTERTAINMENT_COLOR
UI_BUTTON_PRESS_OFFSET
UI_BUTTON_BASE_DEPTH
Os valores concretos devem ser ajustados a partir das imagens de referência.

## 15. Animações e transições
Introduzir animações breves e funcionais, evitando efeitos gratuitos.
Recomendações:
- Preenchimento de Health: transição suave entre valores.
- XP: preenchimento progressivo.
- Level Up: mudança animada dos números, com efeito de contador vertical muito discreto.
- Botões: deslocação imediata ao pressionar e retorno suave ao soltar.
- Céu: interpolação contínua, sem saltos.
- Sol e Lua: movimento dependente exclusivamente da hora.
- Estrelas: aparecimento e desaparecimento gradual.
- Balão de fala: entrada suave, sem efeitos excessivos.
As animações devem ser suficientemente rápidas para não prejudicarem a utilização do jogo.

## 16. Exemplos de estados a testar
Criar uma sequência de testes que inclua:
Estado A: Amanhecer
- 06:30 AM.
- Sol junto ao horizonte esquerdo.
- Gradiente rosa e lilás.
- Personagem sonolenta.
- Health 2.5.
- XP 20/100.
- XP Level 2 → 3.
Estado B: Manhã
- 09:00 AM.
- Sol na metade esquerda do céu.
- Céu azul-claro.
- Personagem satisfeita.
- Health 3.
- XP 45/100.
Estado C: Meio-dia
- 12:00 PM.
- Sol próximo do ponto superior do arco.
- Céu azul luminoso.
- Personagem feliz.
- Health 3.5.
- XP 70/100.
Estado D: Tarde
- 04:30 PM.
- Sol na metade direita.
- Luz progressivamente mais quente.
- Health 4.
- XP 90/100.
Estado E: Pôr-do-sol
- 07:15 PM.
- Sol junto ao horizonte direito, caso essa seja a hora de ocaso configurada.
- Gradientes laranja, rosa e violeta.
- Health 3.7.
- XP 98/100.
Estado F: Noite
- 10:15 PM.
- Lua visível no percurso nocturno.
- Estrelas como pontos brancos.
- Solo azul-escuro.
- Personagem tranquila.
- Health 3.
- XP Level 3 → 4, após a subida de nível.
Estes estados são cenários de teste independentes e não implicam que a saúde tenha obrigatoriamente de seguir essa evolução num dia de jogo.
Além disso, testar pelo menos um botão em estado pressionado e um botão desactivado.

## 17. Critérios de aceitação
A implementação considera-se correcta quando:
1. O HUD corresponde ao desenho plano de referência, com contorno branco fino e fundo a 5% de opacidade.
2. A Health apresenta um coração, o texto Health, o valor actual e exactamente cinco pastilhas.
3. As pastilhas suportam preenchimento parcial contínuo.
4. O XP é apresentado numa barra independente.
5. O XP Level distingue claramente o nível actual do próximo, sendo este mais pequeno e translúcido.
6. A passagem de 100 XP para o nível seguinte funciona correctamente.
7. O relógio está centrado e integra o Pause.
8. O Settings é apenas uma roda dentada branca, sem fundo visível.
9. O balão de fala é branco, arredondado e apresenta contorno escuro, sem sombra.
10. Os quatro botões mantêm as cores e o estilo aprovados e apresentam uma deslocação descendente evidente quando pressionados.
11. O céu muda suavemente ao longo das 24 horas.
12. O Sol nasce à esquerda, passa pelo centro superior e põe-se à direita.
13. A Lua percorre o céu durante a noite.
14. As estrelas são pequenos pontos e surgem progressivamente.
15. O solo curvo acompanha cromaticamente a iluminação.
16. Os elementos gráficos principais são desenhados por código, sem depender de uma colecção de sprites de estados.
17. A interface funciona correctamente em diferentes formatos de smartphone.
18. As funcionalidades originais do jogo continuam operacionais.

## 18. Instrução final à IA de programação
Utiliza as imagens aprovadas como referência gráfica obrigatória.
Não reinventes a composição, a paleta, a hierarquia ou os componentes que já foram aprovados.
O trabalho consiste em traduzir o design existente para um sistema de desenho vectorial programático e funcional.
Começa por analisar o projecto e identificar os componentes reutilizáveis.
Implementa primeiro o ecrã principal, incluindo o fundo dinâmico, o HUD, o relógio, os balões de fala e os quatro botões.
Valida visualmente o resultado em seis momentos do ciclo dia/noite e em diferentes estados de Health, XP e pressão dos botões.
Só depois de o ecrã principal estar visual e funcionalmente validado deves aplicar o sistema gráfico aos outros ecrãs e minijogos.
A implementação deve ser modular, parametrizável, eficiente e fiel ao design aprovado.
Este ecrã é a referência visual do jogo inteiro.


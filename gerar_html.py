import json

# Lê o template do HTML
with open('index.html', 'r', encoding='utf-8') as f:
    template = f.read()

# Lê o arquivo jogos.json
with open('jogos.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Gera o HTML para cada jogo
jogos_html = ''
for jogo in data['jogos']:
    jogo_html = f'''
        <div class="jogo">
            <div class="data-hora">🗓️ {jogo['data']} ⏰ {jogo['horario']}</div>
            <div class="times">⚽ {jogo['jogo']}</div>
            <div class="transmissao">📺 {jogo['ondepassa']}</div>
        </div>'''
    jogos_html += jogo_html

# Substitui o exemplo no template pelos jogos reais
inicio = template.find('<!-- Aqui os jogos serão listados diretamente, sem JavaScript -->')
fim = template.find('</div>', inicio)
novo_html = template[:inicio] + '<!-- Jogos gerados automaticamente -->' + jogos_html + template[fim:]

# Salva o novo HTML
with open('index.html', 'w', encoding='utf-8') as f:
    f.write(novo_html)

print('HTML gerado com sucesso!')

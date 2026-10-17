# Win11 Debian-Like 🐧⚡

Conjunto de scripts e boas práticas para transformar o **Windows 11** em um sistema **enxuto, previsível, sem bloatware, com memória otimizada e manutenção inspirada no Debian GNU/Linux**, sem quebrar compatibilidade com jogos (Steam/NVIDIA) e trabalho.

---

## 🎯 Objetivos

- **Sair do ciclo de "formatar o PC a cada 6 meses"**: Manter o Windows íntegro, sem acúmulo de sobras de registro ou instaladores parasitas.
- **Boot Rápido e Frio**: Redução de ~330 processos para ~210 processos em repouso e liberação de quase **7 GB de RAM**.
- **Gerenciamento de Pacotes Moderno**: Instalação isolada via [Scoop](https://scoop.sh/) (sem poluir o registro do Windows nem pedir UAC) e [Winget](https://learn.microsoft.com/windows/package-manager/winget/).
- **Atualizações Unificadas**: Um único comando (`atualizar` ou `apt-upgrade`) para atualizar pacotes Scoop, Winget, assinaturas do Defender e checar drivers de hardware (NVIDIA, Intel, Lenovo).

---

## 📂 Conteúdo do Repositório

| Arquivo | Descrição |
| :--- | :--- |
| **`atualizar-sistema.ps1`** | Script de manutenção geral estilo `apt update && apt full-upgrade && apt autoremove`. Atualiza Scoop, Winget, checa drivers de hardware (API nativa Windows Update + `nvidia-smi`), atualiza Defender e limpa temporários antigos (> 7 dias). |
| **`admin_debloat.ps1`** | Script de execução única elevada (Admin) para criar ponto de restauração, desativar telemetria, desligar Fast Startup (`hiberfil.sys`), desativar serviços pesados (Lenovo Vantage, Warsaw, McAfee, CCleaner) e instalar substitutos leves como o Lenovo Legion Toolkit. |
| **`setup.ps1`** | Script bootstrap de 1 comando para configurar o Scoop, instalar ferramentas essenciais (`geek`, `everything`, `7zip`, `gh`), limpar chaves de inicialização e criar os atalhos globais. |

---

## 🚀 Como Usar

### 1. Instalação / Configuração Inicial
Clone este repositório e rode no PowerShell:
```powershell
.\setup.ps1
```

Para aplicar as políticas de sistema e desativar bloatwares/telemetria profunda, abra o PowerShell como **Administrador** e execute:
```powershell
powershell -ExecutionPolicy Bypass -File .\admin_debloat.ps1
```

### 2. Rotina Diária de Atualização
Em qualquer terminal (PowerShell ou CMD), basta digitar:
```powershell
atualizar
# ou
apt-upgrade
```

Ou clique no atalho **"Atualizar Sistema"** gerado na sua Área de Trabalho.

#### Parâmetros extras do `atualizar`:
- `atualizar -InstallDrivers`: Baixa e instala drivers e atualizações pendentes do Windows Update (executar como Admin).
- `atualizar -FullCheck`: Executa verificação profunda de integridade do sistema (`DISM` + `sfc /scannow`).

---

## 🛠️ Filosofia "Anti-Windows Rot"

1. **Desinstalações limpas**: Nunca desinstale programas pelo painel nativo; use o **Geek Uninstaller** (`geek`), que remove automaticamente sobras de arquivos e chaves no registro.
2. **Ambiente de Dev isolado**: Utilize WSL2 (Debian/Ubuntu) ou Dev Containers para ferramentas de desenvolvimento pesadas (Python, Node, Docker, bancos de dados).
3. **Scoop primeiro**: Priorize instalar utilitários de linha de comando e ferramentas portáteis via `scoop install <app>` para manter o sistema operacional limpo.

# Como compilar e instalar o MK FLIP (sem Mac — só Windows + iPhone 16)

Você **não precisa de um Mac**. Um Mac na nuvem (GitHub Actions, grátis) compila e
testa; o Windows instala no iPhone pelo Sideloadly. Siga na ordem.

---

## Parte 1 — Subir o projeto para o GitHub (uma vez)

1. Crie um repositório vazio em <https://github.com/new>
   - Nome sugerido: `mkflip`
   - Pode ser **Private**. Não marque "Add README".

2. No Windows, abra o terminal (PowerShell ou Git Bash) **dentro da pasta `MKFlip`**
   (a que tem o `project.yml`) e rode:

   ```bash
   git init
   git add .
   git commit -m "MK FLIP — build inicial"
   git branch -M main
   git remote add origin https://github.com/adilsonmikael/mkflip.git
   git push -u origin main
   ```

   > Se pedir login, use seu usuário `adilsonmikael` e um **Personal Access Token**
   > (GitHub → Settings → Developer settings → Tokens) no lugar da senha.

3. Assim que o push terminar, o GitHub **começa a compilar sozinho**. Veja em:
   `https://github.com/adilsonmikael/mkflip/actions`

---

## Parte 2 — Ver se compilou e passou nos testes

Na aba **Actions** do seu repositório:

- **MK FLIP CI** verde ✅ = compilou e os testes XCTest passaram.
- Vermelho ❌ = abra o job, leia o log do passo "Build + Test". Me mande o erro que eu corrijo.

Isso resolve, sem Mac, os itens "Compilado" e "Testado" da sua exigência de verificação.

---

## Parte 3 — Baixar o aplicativo (.ipa)

1. Na execução verde do Actions, role até **Artifacts**.
2. Baixe **`MKFlip-unsigned-ipa`** → dentro dele vem `MKFlip-unsigned.ipa`.

Esse `.ipa` está **sem assinatura** de propósito — o Sideloadly assina com o seu
Apple ID na hora de instalar.

---

## Parte 4 — Instalar no iPhone 16 pelo Windows (Sideloadly)

1. Instale o **iTunes** (versão da Apple, não da Microsoft Store) e o
   **Sideloadly** (<https://sideloadly.io>) no Windows.
2. Conecte o iPhone 16 por cabo e confie no computador.
3. Abra o Sideloadly:
   - Arraste o `MKFlip-unsigned.ipa` para a janela.
   - Em **Apple account**, coloque seu Apple ID (pode ser grátis).
   - Clique **Start**. Ele reassina e instala.
4. No iPhone: **Ajustes → Geral → VPN e Gerenciamento de Dispositivos** →
   confie no seu Apple ID de desenvolvedor.
5. Abra o MK FLIP.

> **Apple ID grátis:** o app funciona por **7 dias**; depois é só reinstalar pelo
> Sideloadly. Com a conta paga (US$ 99/ano) dura 1 ano e libera TestFlight.

---

## O que NÃO funciona com Apple ID grátis (e por quê)

| Recurso | Grátis | Pago (US$99/ano) |
|---|---|---|
| Todos os módulos de software (crypto, forense, rede, web, OSINT, terminal, IA…) | ✅ | ✅ |
| Bluetooth, Câmera/QR, DNS/rede | ✅ | ✅ |
| **NFC Lab** | ❌ *(entitlement de NFC exige conta paga)* | ✅ |

O MK FLIP já trata isso: o NFC Lab mostra **"NFC indisponível"** em vez de quebrar.
Se o Sideloadly reclamar do entitlement de NFC ao instalar, ative a opção dele para
remover entitlements não suportados — o resto do app instala normalmente.

---

## Resumo do fluxo

```
Windows (escreve código) ──push──▶ GitHub Actions (Mac na nuvem: compila + testa + gera .ipa)
                                                   │
                                            baixa .ipa
                                                   ▼
                                   Sideloadly (Windows) ──cabo──▶ iPhone 16
```

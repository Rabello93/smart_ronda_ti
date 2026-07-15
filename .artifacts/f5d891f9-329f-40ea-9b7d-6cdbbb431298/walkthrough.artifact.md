# Walkthrough - QR Code para PDF

Atualizei a funcionalidade de compartilhamento de QR Code para gerar um documento PDF de alta qualidade em vez de uma imagem JPG.

## Alterações Realizadas

### Operação e Histórico
- **[ronda_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/operation/rounds/pages/ronda_page.dart)** e **[ronda_details_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/operation/rounds/pages/history/ronda_details_page.dart)**:
    - Modifiquei o botão **COMPARTILHAR** no popup de QR Code.
    - Agora, ao clicar em compartilhar, o sistema:
        1. Captura a imagem do QR Code.
        2. Cria um documento PDF (tamanho A6 para facilitar impressão).
        3. Insere o QR Code centralizado no PDF.
        4. Adiciona o número do patrimônio em destaque abaixo do código.
        5. Compartilha o arquivo `.pdf` gerado.

> [!TIP]
> A opção **SALVAR NA GALERIA** continua gerando uma imagem (JPG), pois é o formato padrão esperado pelos aplicativos de fotos do celular.

## Verificação
- O build deve ocorrer sem erros.
- Ao compartilhar um QR Code, o arquivo recebido pelo destinatário deve ter a extensão `.pdf`.

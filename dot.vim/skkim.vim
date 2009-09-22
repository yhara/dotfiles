" vi:set ts=4 sts=2 sw=2 tw=0 nowrap et:
"
" skkim.vim - SKK 風インプットメソッド
"
" Maintainer:  Yasuhiro Matsumoto <mattn_jp@hotmail.com>
" Supervisor:  MURAOKA Taro <koron@tka.att.ne.jp>
" Last Change: Wed, 26 May 2004
" Commands:    <C-J> to start IM
" Require:     SKK-JISYO.L
" Version:     27
" Comment:
"   これは vim で skk (ライクな) 入力を行うスクリプトです。
"   skk の通常入力のみ可能です。また辞書登録も行えません。
"   $VIMRUNTIME/dict/SKK-JISYO-L もしくは変数 skk_im_dictionary
"   で指定された skk 辞書形式のファイルから語句を決定しています。
"   なお、このスクリプトについての動作保証は出来ません。
"   追記：このスクリプトの修正点やご意見はできるだけ優しくお願いします。苦笑
" Concept:
"  01: コンソールでも日本語が入力できる(jfbtermやkon等からも入力できる)
"  02: 複数のエンコーディングに対応(vimが扱える日本語エンコーディングならば対応可能)
"  03: スクリプト実装であることをなるべく見えないようにする
"  04: できる限りの高速化をめざす
" History:
"  27: / 入力対応を追加
"  26: skk_useredraw を追加
"  25: skk_irohatbl をソートして少し高速化
"  24: g:skk_im_loaded の設定で finish する行がコメントアウトされていたのを修正
"  23: SkkEraseCandWord() を削除
"      全て BS で実装するよう修正
"      コマンドラインで SKK できるよう修正
"      サーチモードで SKK できるよう修正
"      勝手ながら skkim_dictionary を skk_im_dictionary に修正
"      勝手ながら skkim_load を skk_im_load に修正
"      勝手ながら skk_marks を skk_im_marks に修正
"      skk_iminsert=2,skk_imcmdline=1,skk_imsearch=1 で SKK モードに移行するよう機能追加
"      またもや送りがな全面修正
"  22: 初回変換の BS を使うよう修正
"      skk_iminsert=2 で SKK モードに移行するよう機能追加
"  21: 'l' モードを実装
"  20: 候補ありで esc 押下するとずれていたのを修正
"  19: SkkGetPreedit() が一文字ずれていたのを修正
"  18: 辞書に ';' があるとそのまま出てしまっていたので、いまのところ表示しないよう修正
"  17: c-j の処理がおかしかったのを修正
"  16: undo の修正により送り仮名あり確定入力するとおかしくなってたのを修正
"      一日に何個リリースしてんだ俺･･･
"  15: undo の制御がおかしかったのを修正
"  14: 辞書登録処理の作りこみを開始(まだ未実装)
"      辞書登録の為に変数をスクリプト変数からバッファ変数へ移行
"  13: 送り仮名あり確定入力すると前の送り仮名が引き継がれてしまう問題を修正
"  12: 入力方法を作り変え(C-R を使って書き直し)
"  11: 10でバグを発見したので修正
"  10: 行頭でも入力出来るように修正
"  09: 文字化けがたまに発生するのを修正(ひとまず入力中は改行できなくした)
"  08: 関数名等修正
"  07: バックスペースでプリエディットをリセットする処理を修正
"  06: 3がどうしても直らんので一時的にはずす
"  05: 4のバグ修正
"  04: 隠しているはずの辞書ファイルにフォーカスがあたった場合閉じるようにした
"  03: undo が使えるようにした
"  02: もろもろ修正
"  01: リリース
" Todo:
"  01: 辞書再起登録
"      現在は再帰登録ウィンドウの実装中

scriptencoding utf-8

"-----------------------------------------------------------------------------
" グローバル変数
"-----------------------------------------------------------------------------
if exists('g:skk_im_loaded')
  finish
endif
let skk_im_loaded = 1

if !exists('g:skk_im_dictionary')
  " 辞書へのパス
  let g:skk_im_dictionary = globpath(&rtp, 'dict/SKK-JISYO.L')
endif

if !exists('g:skk_im_marks')
  " 代替マーク
  let g:skk_im_marks = '▽▼'
endif

"-----------------------------------------------------------------------------
" バッファ変数
"-----------------------------------------------------------------------------
" b:skk_inpstyle : 現在の入力モード('kana','kata')
" b:skk_inplost : 入力途中文字
" b:skk_candword :  変換前の入力文字
" b:skk_candidate : 変換候補一覧
" b:skk_candindex : 変換候補番号
" b:skk_candstartcol : 変換開始位置
" b:skk_okurileft : 送り仮名
" b:skk_okurichar : 送り仮名文字

"-----------------------------------------------------------------------------
" スクリプト変数
"-----------------------------------------------------------------------------
" マーク(未変換)
let s:skk_candmark1 = substitute(skk_im_marks, '\(.\)\(.\)', '\1', '')
" マーク(変換済)
let s:skk_candmark2 = substitute(skk_im_marks, '\(.\)\(.\)', '\2', '')
" コマンドラインも SKK を有効にするかどうか
let s:skk_enable_cmdline = 0
" 辞書登録できるかどうか
let s:skk_enable_regist = 0
" カレント登録ウィンドウ
let s:skk_registwindows = '' 
" :redraw を使用するかどうか
let s:skk_useredraw = 0
" フックする文字一覧
let s:skk_inphook = "abcdefghijklmnopqrstuvwxyz!<#$%&'\"()=^~\\|@`{}+*/<>?_,.-:;[]"
" イロハテーブル
let s:skk_irohatbl = ""
      \."! ！\<NL>"
      \."# ＃\<NL>"
      \."$ ＄\<NL>"
      \."% ％\<NL>"
      \."& ＆\<NL>"
      \."' ’\<NL>"
      \."( （\<NL>"
      \.") ）\<NL>"
      \."* ＊\<NL>"
      \."+ ＋\<NL>"
      \.", 、\<NL>"
      \."- ー\<NL>"
      \.". 。\<NL>"
      \."/ ／\<NL>"
      \.": ：\<NL>"
      \."; ；\<NL>"
      \."< ＜\<NL>"
      \."< ￥\<NL>"
      \."= ＝\<NL>"
      \."> ＞\<NL>"
      \."? ？\<NL>"
      \."@ ＠\<NL>"
      \."[ 「\<NL>"
      \."\" ”\<NL>"
      \."\\ ￥\<NL>"
      \."] 」\<NL>"
      \."^ ＾\<NL>"
      \."_ ＿\<NL>"
      \."` ｀\<NL>"
      \."a あ ア\<NL>"
      \."ba ば バ\<NL>"
      \."be べ ベ\<NL>"
      \."bi び ビ\<NL>"
      \."bo ぼ ボ\<NL>"
      \."bu ぶ ブ\<NL>"
      \."bya びゃ\<NL>"
      \."bye びぇ\<NL>"
      \."byi びぃ\<NL>"
      \."byo びょ\<NL>"
      \."byu びゅ\<NL>"
      \."ca か\<NL>"
      \."ce せ\<NL>"
      \."cha ちゃ\<NL>"
      \."che ちぇ\<NL>"
      \."chi ち\<NL>"
      \."cho ちょ\<NL>"
      \."chu ちゅ\<NL>"
      \."ci し\<NL>"
      \."co こ\<NL>"
      \."cu く\<NL>"
      \."da だ ダ\<NL>"
      \."de で デ\<NL>"
      \."dha でゃ\<NL>"
      \."dhe でぇ\<NL>"
      \."dhi でぃ\<NL>"
      \."dho でょ\<NL>"
      \."dhu でゅ\<NL>"
      \."di ぢ ヂ\<NL>"
      \."do ど ド\<NL>"
      \."du づ ヅ\<NL>"
      \."dya ぢゃ\<NL>"
      \."dye ぢぇ\<NL>"
      \."dyi ぢぃ\<NL>"
      \."dyo ぢょ\<NL>"
      \."dyu ぢゅ\<NL>"
      \."e え エ\<NL>"
      \."fa ふぁ\<NL>"
      \."fe ふぇ\<NL>"
      \."fi ふぃ\<NL>"
      \."fo ふぉ\<NL>"
      \."fu ふ\<NL>"
      \."ga が ガ\<NL>"
      \."ge げ ゲ\<NL>"
      \."gi ぎ ギ\<NL>"
      \."go ご ゴ\<NL>"
      \."gu ぐ グ\<NL>"
      \."gya ぎゃ\<NL>"
      \."gye ぎぇ\<NL>"
      \."gyi ぎぃ\<NL>"
      \."gyo ぎょ\<NL>"
      \."gyu ぎゅ\<NL>"
      \."ha は ハ\<NL>"
      \."he へ ヘ\<NL>"
      \."hi ひ ヒ\<NL>"
      \."ho ほ ホ\<NL>"
      \."hu ふ フ\<NL>"
      \."hya ひゃ\<NL>"
      \."hye ひぇ\<NL>"
      \."hyi ひぃ\<NL>"
      \."hyo ひょ\<NL>"
      \."hyu ひゅ\<NL>"
      \."i い イ\<NL>"
      \."ja じゃ\<NL>"
      \."je じぇ\<NL>"
      \."ji じ\<NL>"
      \."jo じょ\<NL>"
      \."ju じゅ\<NL>"
      \."jya じゃ\<NL>"
      \."jye じぇ\<NL>"
      \."jyi じぃ\<NL>"
      \."jyo じょ\<NL>"
      \."jyu じゅ\<NL>"
      \."ka か カ\<NL>"
      \."ke け ケ\<NL>"
      \."ki き キ\<NL>"
      \."ko こ コ\<NL>"
      \."ku く ク\<NL>"
      \."kya きゃ\<NL>"
      \."kye きぇ\<NL>"
      \."kyi きぃ\<NL>"
      \."kyo きょ\<NL>"
      \."kyu きゅ\<NL>"
      \."ma ま マ\<NL>"
      \."me め メ\<NL>"
      \."mi み ミ\<NL>"
      \."mo も モ\<NL>"
      \."mu む ム\<NL>"
      \."mya みゃ\<NL>"
      \."mye みぇ\<NL>"
      \."myi みぃ\<NL>"
      \."myo みょ\<NL>"
      \."myu みゅ\<NL>"
      \."n ん ン\<NL>"
      \."na な ナ\<NL>"
      \."ne ね ネ\<NL>"
      \."ni に ニ\<NL>"
      \."nn ん\<NL>"
      \."no の ノ\<NL>"
      \."nu ぬ ヌ\<NL>"
      \."nya にゃ\<NL>"
      \."nye にぇ\<NL>"
      \."nyi にぃ\<NL>"
      \."nyo にょ\<NL>"
      \."nyu にゅ\<NL>"
      \."o お オ\<NL>"
      \."pa ぱ パ\<NL>"
      \."pe ぺ ペ\<NL>"
      \."pi ぴ ピ\<NL>"
      \."po ぽ ポ\<NL>"
      \."pu ぷ プ\<NL>"
      \."pya ぴゃ\<NL>"
      \."pye ぴぇ\<NL>"
      \."pyi ぴぃ\<NL>"
      \."pyo ぴょ\<NL>"
      \."pyu ぴゅ\<NL>"
      \."ra ら ラ\<NL>"
      \."re れ レ\<NL>"
      \."ri り リ\<NL>"
      \."ro ろ ロ\<NL>"
      \."ru る ル\<NL>"
      \."rya りゃ\<NL>"
      \."rye りぇ\<NL>"
      \."ryi りぃ\<NL>"
      \."ryo りょ\<NL>"
      \."ryu りゅ\<NL>"
      \."sa さ サ\<NL>"
      \."se せ セ\<NL>"
      \."sha しゃ\<NL>"
      \."she しぇ\<NL>"
      \."shi し\<NL>"
      \."sho しょ\<NL>"
      \."shu しゅ\<NL>"
      \."si し シ\<NL>"
      \."so そ ソ\<NL>"
      \."su す ス\<NL>"
      \."sya しゃ\<NL>"
      \."sye しぇ\<NL>"
      \."syi しぃ\<NL>"
      \."syo しょ\<NL>"
      \."syu しゅ\<NL>"
      \."ta た タ\<NL>"
      \."te て テ\<NL>"
      \."tha てゃ\<NL>"
      \."the てぇ\<NL>"
      \."thi てぃ\<NL>"
      \."tho てょ\<NL>"
      \."thu てゅ\<NL>"
      \."ti ち チ\<NL>"
      \."to と ト\<NL>"
      \."tsa つぁ\<NL>"
      \."tse つぇ\<NL>"
      \."tsi つぃ\<NL>"
      \."tso つぉ\<NL>"
      \."tsu つ\<NL>"
      \."tu つ ツ\<NL>"
      \."tya ちゃ\<NL>"
      \."tye ちぇ\<NL>"
      \."tyi ちぃ\<NL>"
      \."tyo ちょ\<NL>"
      \."tyu ちゅ\<NL>"
      \."u う ウ\<NL>"
      \."wa わ ワ\<NL>"
      \."we ゑ エ\<NL>"
      \."wi ゐ イ\<NL>"
      \."wo を ヲ\<NL>"
      \."wu う ウ\<NL>"
      \."xa ぁ ァ\<NL>"
      \."xe ぇ ェ\<NL>"
      \."xi ぃ ィ\<NL>"
      \."xo ぉ ォ\<NL>"
      \."xtsu っ ッ\<NL>"
      \."xtu っ\<NL>"
      \."xu ぅ ゥ\<NL>"
      \."xya ゃ ャ\<NL>"
      \."xyo ょ ョ\<NL>"
      \."xyu ゅ ュ\<NL>"
      \."ya や ヤ\<NL>"
      \."yo よ ヨ\<NL>"
      \."yu ゆ ユ\<NL>"
      \."za ざ ザ\<NL>"
      \."ze ぜ ゼ\<NL>"
      \."zi じ ジ\<NL>"
      \."zo ぞ ゾ\<NL>"
      \."zu ず ズ\<NL>"
      \."zya じゃ\<NL>"
      \."zye じぇ\<NL>"
      \."zyi じぃ\<NL>"
      \."zyo じょ\<NL>"
      \."zyu じゅ\<NL>"
      \."{ ｛\<NL>"
      \."| ｜\<NL>"
      \."} ｝\<NL>"
      \."~ 〜\<NL>"

" イロハテーブルのサイズ
let s:skk_irohasiz = strlen(substitute(s:skk_irohatbl, "[^\<NL>]*\<NL>\\?", 'a', 'g'))

"-----------------------------------------------------------------------------
" SkkQueryIrohatable() : イロハテーブルから指定番号のペアを取得する
"  cnt : 番号
"  戻り値 : ペア
"-----------------------------------------------------------------------------
function! s:SkkQueryIrohatable(cnt)
  if exists('s:skk_irohatbl')
    let cnt = 0
    let dat = s:skk_irohatbl
    while dat != ''
      let line = matchstr(dat, "^[^\<NL>]*")
      let dat = strpart(dat, strlen(line) + 1)
      let s:skk_irohatbl_{cnt} = line
      let cnt = cnt + 1
    endwhile
    unlet s:skk_irohatbl
  endif
  return s:skk_irohatbl_{a:cnt}
endfunction

"-----------------------------------------------------------------------------
" SkkSearchChar() : ローマ字から平仮名を検索する
"  char : 検索するローマ文字
"  戻り値 : 検索結果
"-----------------------------------------------------------------------------
function! s:SkkSearchChar(char)
  let cnt = 0
  let dup = 0
  let res = ''
  while 1
    if cnt >= s:skk_irohasiz
      break
    endif
    let tok = s:SkkQueryIrohatable(cnt)
    if stridx(tok, a:char) == 0
      let res = res . tok . "\<NL>"
    elseif res != ''
      break
    endif
    let cnt = cnt + 1
  endwhile
  return res
endfunction

"-----------------------------------------------------------------------------
" SkkCharConv() : 平仮名カタカナ変換
"  char : 変換する文字
"  flag : 変換方法(0:カタカナから平仮名へ,1:平仮名からカタカナへ)
"  戻り値 : 変換された文字
"-----------------------------------------------------------------------------
function! s:SkkCharConv(char, flag)
  let cnt = 0
  let dup = 0
  let res = ''
  let mx = '\S\+\s\(\S\+\)\s\(.*\)'
  while 1
    if cnt >= s:skk_irohasiz
      break
    endif
    let tok = s:SkkQueryIrohatable(cnt)
    if a:flag == 0
      if matchstr(tok, ' ' . a:char . '$') != ""
        return substitute(tok, mx, '\1', '')
      endif
    elseif a:flag == 1
      if stridx(tok, ' ' . a:char . ' ') != -1
        return substitute(tok, mx, '\2', '')
      endif
    endif
    let cnt = cnt + 1
  endwhile
  return a:char
endfunction

"-----------------------------------------------------------------------------
" SkkOpenDict() : 辞書を開く
"  戻り値 : なし
"-----------------------------------------------------------------------------
function! s:SkkOpenDict()
  let nr = bufwinnr(g:skk_im_dictionary)
  if nr != -1
    if nr != winnr()
      silent! exec nr.'wincmd w'
    endif
  else
    silent exec '1 split ' . g:skk_im_dictionary
    setlocal buftype=nowrite
  endif
endfunction

"-----------------------------------------------------------------------------
" SkkHideDict() : 辞書を隠す
"  戻り値 : なし
"-----------------------------------------------------------------------------
function! s:SkkHideDict()
  let nr = bufwinnr(g:skk_im_dictionary)
  if nr != -1
    if nr != winnr()
      silent! exec nr.'wincmd w'
    endif
    silent! hide
  endif
endfunction

"-----------------------------------------------------------------------------
" SkkRegistDict() : 辞書を登録する
"  word : 登録するキー
"  cand : 登録する値
"  戻り値 : なし
"-----------------------------------------------------------------------------
function! s:SkkRegistDict(word, cand)
  " Not implement... ヽ(`Д´)ﾉｳﾜｰﾝ
endfunction

"-----------------------------------------------------------------------------
" SkkCloseDict() : 辞書を閉じる
"  戻り値 : なし
"-----------------------------------------------------------------------------
function! s:SkkCloseDict()
  let nr = bufwinnr(g:skk_im_dictionary)
  if nr != -1
    if nr != winnr()
      silent! exec nr.'wincmd w'
    endif
    silent! bw!
  endif
endfunction

"-----------------------------------------------------------------------------
" SkkSearchFromDict() : 辞書から検索する
"  word : 検索する単語
"-----------------------------------------------------------------------------
function! s:SkkSearchFromDict(word)
  let ret = ''
  " 辞書をそっと開く
  call s:SkkOpenDict()
  silent! normal! gg
  if search('^' . a:word . ' ', 'w')
    " 辞書をそっと探す
    let ret = substitute(getline('.'), '^.*\s/\(.*\)$', '\1', '')
    let ret = substitute(ret, '/', "\<NL>", 'g')
  else
    let ret = ''
  endif
  " 辞書をそっと閉じる
  call s:SkkHideDict()
  return ret
endfunction

"-----------------------------------------------------------------------------
" SkkReset() : 現在入力中のプリエディットをリセットする
"  戻り値 : なし
"-----------------------------------------------------------------------------
function! s:SkkReset()
  " リセットする
  " ただしモードなどは変更させない 
  let b:skk_inplost = ''
  let b:skk_okurileft = ''
  let b:skk_okurichar = ''
  let b:skk_candidate = ''
  let b:skk_candindex = 0
  let b:skk_candword = ''
  let b:skk_candstartcol = -1
  let b:skk_slashmode = 0
endfunction

"-----------------------------------------------------------------------------
" SkkGetCand() : 候補取得処理
"  戻り値 : 現在の候補
"-----------------------------------------------------------------------------
function s:SkkGetCand()
  let idx = b:skk_candindex
  let cnd = b:skk_candidate
  if idx == 0 || idx == ''
    let ret = matchstr(cnd, "^[^\<NL>]*")
  else
    let ret = substitute(cnd, "^\\%([^\<NL>]*\<NL>\\)\\{" . idx . "}\\([^\<NL>]*\\).*", '\1', '')
  endif
  let ret = substitute(ret, ';.*', '', '')
  return ret
endfunction

"-----------------------------------------------------------------------------
" SkkGetPreedit() : 現在入力中のプリエディットを取得する
"  戻り値 : 入力中のプリエディット
"-----------------------------------------------------------------------------
function! s:SkkGetPreedit()
  let word = ''
  if b:skk_candstartcol != -1
    if s:SkkIsCmdline() == 0
      " コマンドラインでないならば
      let word = getline('.')
      let startcol = b:skk_candstartcol-1+strlen(s:skk_candmark1)
      let word = strpart(word, startcol, col('.')-startcol-1)
    else
      " コマンドラインならば
      let word = getcmdline()
      let startcol = b:skk_candstartcol-1+strlen(s:skk_candmark1)
      let word = strpart(word, startcol, getcmdpos()-startcol-1)
    endif
  endif
  return word
endfunction

"-----------------------------------------------------------------------------
" SkkBackspace() : 現在入力中のプリエディットを削除する
"  ctrl_g : ctrl_g でのバックスペースかどうか
"  戻り値 : 変換文字からプリエディットへ
"-----------------------------------------------------------------------------
function! s:SkkBackspace(ctrl_g)
  let inschar = ''

  if b:skk_inpstyle == 'roma'
    " 直接入力
    let inschar = "\<c-h>"
  elseif b:skk_candidate != ''
    " 変換中ならばキャンセルさせる
    let bs = substitute(s:skk_candmark2 . s:SkkGetCand(), ".", "\<c-h>", "g")
    " 未変換にする
    let inschar = bs . s:skk_candmark1 . b:skk_candword
    let b:skk_okurileft = ''
    let b:skk_okurichar = ''
    let b:skk_candidate = ''
    let b:skk_inplost = ''
  elseif b:skk_candstartcol != -1
    if a:ctrl_g == 0
      " Ctrl-G 出ない場合はバックスペース扱い
      if s:SkkIsCmdline() == 0 && getline('.') == ''
        " 行またがりのバックスペース対応
        " 文字を一文字入れて消させる(ワークアラウンド)
        exec "normal! kAx"
      endif
      let inschar = "\<c-h>"
      let b:skk_okurileft = ''
      let b:skk_okurichar = ''
      let b:skk_inplost = ''
    else
      " Ctrl-G ならばプリエディット自体をやめる
      let inschar = substitute(s:skk_candmark1 . s:SkkGetCand(), ".", "\<c-h>", "g")
      call s:SkkReset()
      if exists('b:skk_registword')
        call s:SkkCloseRegistWindow(1)
        call s:SkkReset()
      endif
    endif
  else
    let inschar = "\<c-h>"
  endif

  if b:skk_candstartcol != -1
    " プリエディットありならば
    if strlen(substitute(s:SkkGetPreedit(), '.', '.', 'g')) == 1
      " バックスペースでマーク前まできたら、プリエディットもやめる
      let inschar = inschar . "\<c-h>"
      call s:SkkReset()
    endif
  endif

  if exists('b:skk_registword') && getline('.') =~ '^.*:$'
    " 登録ウィンドウにて語句なしにバックスペースならば
    " 登録ウィンドウ自体閉じてしまう
    call s:SkkCloseRegistWindow(1)
    let inschar = ''
  endif

  if s:SkkIsCmdline() == 0
    " コマンドラインでないならば
    match none
  endif
  return inschar
endfunction

"-----------------------------------------------------------------------------
" SkkCandidate() : 変換処理
"  decide : 確定方法(0:変換開始,1:確定,2:平仮名モードで確定,3:カタカナモードで確定)
"  newline : 改行を入れるかどうか
"  戻り値 : 変換された文字列
"-----------------------------------------------------------------------------
function! s:SkkCandidate(decide, newline)
  let inschar = ''
  let need_newline = a:newline

  if s:SkkIsCmdline() != 0
    " 再描画をきれいに...
    echo ''
    redraw
  endif

  " 直接入力
  if b:skk_inpstyle == 'roma'
    if a:decide == 0
      return ' '
    else
      if s:SkkIsCmdline() == 0
        " コマンドラインでないならば
        let b:skk_inpstyle = 'kana'
        return ''
      endif
    endif
  endif

  if a:decide == 0
    " 変換処理の場合
    if b:skk_candstartcol == -1
      " プリエディットが開始していないならばスペース挿入扱い
      let inschar = ' '
    elseif b:skk_candidate == ''
      " １回目の候補選択の場合
      if filereadable(g:skk_im_dictionary)
        let word = s:SkkGetPreedit()
        if b:skk_inpstyle == 'kata'
          " 検索の為にカタカナを平仮名に戻す
          let word = substitute(word, '\(.\)', '\=s:SkkCharConv(submatch(1), 0)', 'g')
        endif
        " 送り仮名を足す
        if b:skk_okurichar != ''
          if word =~ "^.*っ$"
            let b:skk_okurileft = 'っ' . b:skk_okurileft
            let word = strpart(word, 0, strlen(word) - strlen('っ'))
          elseif word =~ "^.*ん$"
            let b:skk_okurileft = 'ん' . b:skk_okurileft
            let word = strpart(word, 0, strlen(word) - strlen('ん'))
          endif
          let word = word . b:skk_okurichar
        endif
        let b:skk_candword = word
        let b:skk_candidate = s:SkkSearchFromDict(word)
        if b:skk_candidate == ''
          " みつからない
          if s:skk_enable_regist == 1 && s:SkkIsCmdline() == 0
            " 登録可能ならば登録ウィンドウを生成(現状コマンドラインは見対応)
            call s:SkkOpenRegistWindow(word)
            let inschar = ''
          else
            echohl ErrorMsg
            echo "No Entry for " . word
            echohl None
            let inschar = ''
          endif
        else
          " みつかったので候補を表示し、色を設定
          let b:skk_candindex = 0
          let cand = s:SkkGetCand()
          let bs = substitute(s:skk_candmark2 . s:SkkGetPreedit(), ".", "\<c-h>", "g")
          let inschar = s:skk_candmark2 . cand
          if s:SkkIsCmdline() == 0
            " コマンドラインでないならば
            exec 'silent! match Search /\%'.line('.').'l\%>'.b:skk_candstartcol.'c\%<'.(b:skk_candstartcol+strlen(inschar)).'c/'
          endif
          let inschar = bs . inschar . b:skk_okurileft
        endif
      else
        " 辞書が開けない
        echohl ErrorMsg
        echo "No Dictionary"
        echohl None
        let inschar = s:skk_candmark1 . s:SkkGetPreedit()
      endif
    else
      " ２回目からの候補選択の場合
      " 候補をローテート
      let b:skk_candindex = b:skk_candindex + 1
      let cand = s:SkkGetCand()
      if cand == ''
        let b:skk_candindex = 0
        let cand = s:SkkGetCand()
      endif

      " 新しい候補を表示
      let bs = substitute(s:skk_candmark2 . s:SkkGetPreedit(), ".", "\<c-h>", "g")
      let inschar = s:skk_candmark2 . cand
      if s:SkkIsCmdline() == 0
        " コマンドラインでないならば
        exec 'silent! match Search /\%'.line('.').'l\%>'.b:skk_candstartcol.'c\%<'.(b:skk_candstartcol+strlen(inschar)).'c/'
      endif
      let inschar = bs . inschar . b:skk_okurileft
    endif
  else
    " 確定処理の場合
    if b:skk_candstartcol != -1
      " プリエディット中ならば変換候補を挿入
      if b:skk_candidate != ''
        let cand = s:SkkGetCand()
        let bs = substitute(s:skk_candmark2 . s:SkkGetPreedit(), ".", "\<c-h>", "g")
        let inschar = bs . cand
      else
        let bs = substitute(s:skk_candmark1 . s:SkkGetPreedit(), ".", "\<c-h>", "g")
        let inschar = bs . s:SkkGetPreedit()
      endif
      let inschar = inschar . b:skk_okurileft
    elseif need_newline == 0
      " 変換なしの C-J だったので平仮名モードへ移行
      let b:skk_inpstyle = 'kana'
    endif
    call s:SkkReset()

    if a:decide == 2
      " カタカナ確定の処理
      let b:skk_inpstyle = 'kata'
    endif

    if inschar == '' && exists('b:skk_registword')
      let mx = '^\([^:]\+\):\(.*\)$'
      let line = getline('.')
      let regword = substitute(line, mx, '\1', '')
      let regcand = substitute(line, mx, '\2', '')
      " 辞書に登録する
      call s:SkkRegistDict(regword, regcand)
      call s:SkkCloseRegistWindow(0)
      let bs = substitute(s:skk_candmark1 . s:SkkGetPreedit(), ".", "\<c-h>", "g")
      call s:SkkReset()
      let inschar = inschar . bs . regcand
      " 改行させない
      let need_newline = 0
    endif
    if s:SkkIsCmdline() == 0
      " コマンドラインでないならば
      match none
    endif
  endif

  if b:skk_inpstyle == 'kata'
    " カタカナ入力の場合...
    let inschar = substitute(inschar, '\(.\)', '\=s:SkkCharConv(submatch(1), 1)', 'g')
  endif
  if need_newline != 0
    if s:SkkIsCmdline() == 0
      " コマンドラインでないならば
      let inschar = inschar . "\n"
    else
      " 次回コマンドラインで SKK から始まると嫌なのでリセットしてしまう
      call SkkToggle(1)
    endif
  endif
  return inschar
endfunction

"-----------------------------------------------------------------------------
" SkkInsert() : 挿入処理
"  code : 挿入しようとしている文字コード
"  戻り値 : 挿入する文字(もしくは確定された文字列)
"-----------------------------------------------------------------------------
function! s:SkkInsert(code)
  let inschar = ''
  let achar = nr2char(a:code)

  if s:SkkIsCmdline() != 0
    " 再描画をきれいに...
    echo ''
    redraw
  endif

  if b:skk_inpstyle == 'roma'
    " 直接入力
  elseif b:skk_inpstyle != 'roma' && achar == 'l' && b:skk_candstartcol == -1
    " ローマ字モード
    let b:skk_inpstyle = 'roma'
    " この入力は無視する
    let achar = ''
  elseif b:skk_inpstyle == 'kana' && achar == 'q'
    " カタカナモード
    if b:skk_candstartcol != -1
      " 未確定を確定してしまう
      let inschar = inschar . s:SkkCandidate(2, 0)
      let b:skk_inpstyle = 'kana'
    else
      let b:skk_inpstyle = 'kata'
    endif
    " この入力は無視する
    let achar = ''
  elseif (stridx(toupper(s:skk_inphook), achar) >= 0 && achar =~ '[A-Z]') || (b:skk_candstartcol == -1 && achar == '/')
    " 頭文字大文字で始まる...
    if b:skk_candidate != ''
      " 変換済みならば確定してしまう
      let oldcandcol = b:skk_candstartcol
      let cand = s:SkkCandidate(1, 0)
      let candlen = strlen(cand)
      let bschar = "\<c-h>"
      let bsstart = 0
      while strpart(cand, bsstart, strlen(bschar)) == bschar
        let candlen = candlen - strlen(bschar)
        let bsstart = bsstart + strlen(bschar)
      endwhile
      let inschar = cand . s:skk_candmark1
      let b:skk_candstartcol = oldcandcol + candlen
    else
      " 変換開始ならば変換開始マークを表示
      if b:skk_candstartcol != -1
        let b:skk_okurichar = tolower(achar)
      else
        call s:SkkReset()
        let inschar = s:skk_candmark1
        if s:SkkIsCmdline() == 0
          " コマンドラインでないならば
          let b:skk_candstartcol = col('.')
        else
          let b:skk_candstartcol = getcmdpos()
        endif
        if achar == '/'
          let achar = ''
          let b:skk_slashmode = 1
        endif
      endif
    endif
  elseif b:skk_candidate != ''
    " 変換済みならば確定してしまう
    let cnd = s:SkkCandidate(1, 0)
    let inschar = inschar . cnd
    let b:skk_inplost = ''
  endif

  if achar != ''
    if b:skk_slashmode == 1
      if achar != ''
        let inschar = inschar . achar
      endif
    else
      " 直接入力
      if b:skk_inpstyle == 'roma'
        return achar
      endif

      " 通常入力処理ならば...
      let achar = tolower(achar)
      let dic = s:SkkSearchChar(b:skk_inplost . achar)
      if dic != ''
        let len = strlen(substitute(dic, "[^\<NL>]*\<NL>\\?", 'a', 'g'))
      else
        let len = 0
      endif

      let mx = '^\S\+\s\(\S\+\).*\n'
      if len == 0 && b:skk_inplost != ''
        let kchar = ''
        if b:skk_inplost[0] == achar
          " 前回入力と今回入力が同じであったので 'っ' を挿入する
          let kchar = 'っ'
        elseif b:skk_inplost[0] == 'n'
          " n で始まる文字が完了しなかったので 'ん' を挿入する
          let kchar = 'ん'
        endif
        let inschar = inschar . kchar
        let b:skk_inplost = achar
      elseif len == 1
        if b:skk_okurichar != ''
          " 送り仮名が既にあるならば変換開始
          let dic = s:SkkSearchChar(b:skk_inplost . achar)
          let dic = substitute(dic, mx, '\1', '')
          let b:skk_okurileft = dic
          let cnd = s:SkkCandidate(0, 0)
          let cnd = substitute(cnd, '\(.\+\)[a-z]', '\1', '')
          let inschar = cnd
        else
          " 1文字で完了している文字はそのまま入力を設定
          let dic = substitute(dic, mx, '\1', '')
          let b:skk_inplost = ''
          let inschar = inschar . dic
        endif
      elseif len > 1
        " 1文字で終わらない文字は次回入力に入力を足す
        let b:skk_inplost = b:skk_inplost . achar
      else
        " 当てはまらない場合はそのままを入力
        let b:skk_inplost = ''
        let inschar = inschar . achar
      endif
    endif
  endif

  if b:skk_inpstyle == 'kata'
    " カタカナ入力の場合...
    let inschar = substitute(inschar, '\(.\)', '\=s:SkkCharConv(submatch(1), 1)', 'g')
  endif
  if s:skk_useredraw == 1
    redraw
  endif
  return inschar
endfunction

"-----------------------------------------------------------------------------
" SkkOpenRegistWindow() : 辞書登録ウィンドウ表示
"  word : 登録する文字列
"  戻り値 : なし
"-----------------------------------------------------------------------------
function s:SkkOpenRegistWindow(word)
  let title = "===SKK=REGIST==="
  let nr = bufwinnr(title)
  if nr != -1
    silent! exec nr.'wincmd w'
  else
    " 登録用ウィンドウを作る
    exec "silent! 1sp " . title
    setlocal buftype=nowrite
    setlocal bufhidden=delete
    setlocal nonumber
    setlocal nowrap
    setlocal norightleft
    setlocal foldcolumn=0
    setlocal noswapfile
  endif
  let b:skk_mode = 0
  call SkkToggle(0)
  " 登録キューに溜め込む
  let s:skk_registwindows = s:skk_registwindows . a:word . "\n"
  let b:skk_registword = a:word
  silent! %d
  call setline(1, a:word . ':')
  startinsert!
endfunction

"-----------------------------------------------------------------------------
" SkkCloseRegistWindow() : 辞書登録ウィンドウ非表示
"  cancel : キャンセルかどうか(0:しない,1:する)
"  戻り値 : 呼び出し元があるかどうか(0:なし,1:あり)
"-----------------------------------------------------------------------------
function s:SkkCloseRegistWindow(cancel)
  let title = "===SKK=REGIST==="
  let nr = bufwinnr(title)
  if nr != -1
    silent! exec nr.'wincmd w'
    let word = ''
    if a:cancel == 0
      " キャンセルでないならば
      " 登録キューから削除する
      let s:skk_registwindows = substitute(s:skk_registwindows, b:skk_registword . '\n', '', 'g')
      if s:skk_registwindows != ''
        if s:skk_registwindows =~ '^' . b:skk_registword . '\n'
          let word = substitute(s:skk_registwindows, '^\(.*\)\n$', '\1', '')
        else
          let word = substitute(s:skk_registwindows, '.*\n\(.*\)\n$', '\1', '')
        endif
        let word = substitute(word, '\n', '', 'g')
      endif
      if word == ''
        " 最後の登録ウィンドウを消す
        silent! bw!
      endif
    else
      " 登録ウィンドウを消す
      silent! bw!
    endif
    return word
  endif
  return ''
endfunction

"-----------------------------------------------------------------------------
" SkkIsCmdline() : コマンドライン内での SKK かどうか
"  戻り値 : SKK モードかどうか(0:でない,1:である)
"-----------------------------------------------------------------------------
function! s:SkkIsCmdline()
  if exists('*getcmdpos')
    if getcmdpos() != 0
      return 1
    else
      return 0
    endif
  else
    return 0
  endif
endfunction

"-----------------------------------------------------------------------------
" SkkSetupImmodeHook() : iminsert, imcmdline, imsearch の実装
"  戻り値 : なし
"-----------------------------------------------------------------------------
function! s:SkkSetupImmodeHook()
  let modehook = ''
  " iminsert=2 の対応
  if exists('g:skk_iminsert') && g:skk_iminsert == 2
    let modehook = modehook . 'iIaAoO'
  endif
  " imcmdline の対応
  if exists('g:skk_imcmdline') && g:skk_imcmdline == 1
    let modehook = modehook . ':'
  endif
  " imsearch の対応
  if exists('g:skk_imsearch') && g:skk_imsearch == 1
    let modehook = modehook . '/'
  endif

  let cnt = 0
  let len = strlen(modehook)
  while cnt < len
    exec "nnoremap ".modehook[cnt]." ".modehook[cnt]."<c-r>=SkkToggle(0)<cr>"
    let cnt = cnt + 1
  endwhile
endfunction

"-----------------------------------------------------------------------------
" SkkToggle() : SKKモードトグル処理
"  forceoff : 強制終了(0:しない,1:する)
"  戻り値 : なし
"-----------------------------------------------------------------------------
function! SkkToggle(forceoff)
  let inschar = ''
  let cnt = 0
  let len = strlen(s:skk_inphook)
  if (exists('b:skk_mode') == 0 || b:skk_mode == 0) && !a:forceoff
    let b:skk_mode = 1
    while cnt < len
      " フックする文字を取得する
      let char = s:skk_inphook[cnt]
      let name = char
      let cnt = cnt + 1
      if char == '|'
        let name = '<bar>'
      endif
      " フックする
      exec "inoremap <silent> <buffer> ".name." <c-r>=<SID>SkkInsert(".char2nr(char).")<cr>"
      if char =~ '[a-z]'
        " 大文字用にもフックする
        let char = toupper(char)
        let name = char
        exec "inoremap <silent> <buffer> ".name." <c-r>=<SID>SkkInsert(".char2nr(char).")<cr>"
      endif
    endwhile
    " その他 SKK ライクになるようにフックする
    exec "inoremap <silent> <buffer> <space> <c-r>=<SID>SkkCandidate(0,0)<cr>"
    exec "inoremap <silent> <buffer> <bs> <c-r>=<SID>SkkBackspace(0)<cr>"
    exec "inoremap <silent> <buffer> <c-w> <c-r>=<SID>SkkBackspace(0)<cr>"
    exec "inoremap <silent> <buffer> <c-h> <c-r>=<SID>SkkBackspace(0)<cr>"
    exec "inoremap <silent> <buffer> <c-g> <c-r>=<SID>SkkBackspace(1)<cr>"
    exec "inoremap <silent> <buffer> <cr> <c-r>=<SID>SkkCandidate(1,1)<cr>"
    exec "inoremap <silent> <buffer> <c-j> <c-r>=<SID>SkkCandidate(1,0)<cr>"
    exec "inoremap <silent> <buffer> <left> <nop>"
    exec "inoremap <silent> <buffer> <right> <nop>"
    exec "inoremap <silent> <buffer> <up> <nop>"
    exec "inoremap <silent> <buffer> <down> <nop>"
    exec "inoremap <silent> <buffer> <home> <nop>"
    exec "inoremap <silent> <buffer> <end> <nop>"
    exec "inoremap <silent> <buffer> <pageup> <nop>"
    exec "inoremap <silent> <buffer> <pagedow> <nop>"
    exec "inoremap <silent> <buffer> <esc> <c-r>=SkkToggle(1)<cr><esc>"
    if s:skk_enable_cmdline == 1
      " コマンドラインもフックする
      exec "cnoremap <silent> <buffer> <esc> <c-r>=SkkToggle(1)<cr><esc>"
      let cnt = 0
      while cnt < len
        " フックする文字を取得する
        let char = s:skk_inphook[cnt]
        let name = char
        let cnt = cnt + 1
        if char == '|'
          let name = '<bar>'
        endif
        " フックする
        exec "cnoremap <buffer> ".name." <c-r>=<SID>SkkInsert(".char2nr(char).")<cr>"
        if char =~ '[a-z]'
          " 大文字用にもフックする
          let char = toupper(char)
          let name = char
          exec "cnoremap <buffer> ".name." <c-r>=<SID>SkkInsert(".char2nr(char).")<cr>"
        endif
      endwhile
      exec "cnoremap <buffer> <esc> <c-r>=SkkToggle(1)<cr><esc>"
      exec "cnoremap <buffer> <space> <c-r>=<SID>SkkCandidate(0,0)<cr>"
      exec "cnoremap <buffer> <bs> <c-r>=<SID>SkkBackspace(0)<cr>"
      exec "cnoremap <buffer> <c-g> <c-r>=<SID>SkkBackspace(1)<cr>"
      " (注) インサートモードのフックに比べ <cr> が一つ多い
      " コマンドラインでは <c-r>="\<cr>" が ^M になってしまう問題の予防策
      exec "cnoremap <buffer> <cr> <c-r>=<SID>SkkCandidate(1,1)<cr><cr>"
      exec "cnoremap <buffer> <c-j> <c-r>=<SID>SkkCandidate(1,0)<cr>"
    endif
    " バッファ変数をクリアしておく
    let b:skk_candword = ''
    let b:skk_candidate = ''
    let b:skk_candstartcol = -1
    let b:skk_candindex = 0
    let b:skk_okurichar = ''
    let b:skk_okurileft = ''
    let b:skk_inplost = ''
    let b:skk_inpstyle = 'kana'
    let b:skk_registwindows = ''
    let b:skk_slashmode = 0
  elseif exists('b:skk_candidate')
    " SKK フックしているバッファならば
    if exists('b:skk_registword')
      " 登録ウィンドウが開いているならば消す
      call s:SkkCloseRegistWindow(1)
    else
      if b:skk_candidate != ''
        " 変換途中なら確定してまえ
        let inschar = s:SkkCandidate(1, 0)
      elseif b:skk_candstartcol != -1
        " 入力途中なら消してまえ
        let inschar = substitute(s:skk_candmark1 . s:SkkGetPreedit(), ".", "\<bs>", "g")
      elseif s:SkkIsCmdline() != 0
        " 再描画をきれいに...
        echo ''
        redraw
        let inschar = "\<c-u>"
      endif
      " 辞書を閉じる
      call s:SkkCloseDict()
      let b:skk_mode = 0
      " フックを消す
      exec "imapclear <buffer>"
      exec "cmapclear <buffer>"
      " 次の開始用に...
      inoremap <silent> <c-j> <c-o>:call SkkToggle(0)<cr>
    endif
  endif
  return inschar
endfunction

" デフォルトで C-J を SKK モード ON にマップする
inoremap <silent> <c-j> <c-r>=SkkToggle(0)<cr>
if s:skk_enable_cmdline == 1
  cnoremap <silent> <c-j> <c-r>=SkkToggle(0)<cr>
endif

if exists('skk_iminsert') || exists('skk_imcmdline') || exists('skk_imsearch')
  call s:SkkSetupImmodeHook()
endif

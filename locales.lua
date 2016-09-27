
-- EnUS (default locale)
local L = LibStub('AceLocale-3.0'):NewLocale('2048', 'enUS', true)
if not L then return end

L['Play while you wait to play!'] = true

L['Old settings reset to defaults - sorry about that.'] = true

L['MOVES'] = true
L['SCORE'] = true
L['BEST'] = true

L['You won!'] = true
L['Game over!'] = true
L['Restart?'] = true
L['New game'] = true
L['Restart'] = true
L['Keep playing'] = true
L['Yes'] = true
L['No'] = true

L['Enable keyboard use'] = true
L['Window scale'] = true
L['Join the numbers and get to the |cFFFF00002048|r tile!'] = true

--frFR
L = LibStub('AceLocale-3.0'):NewLocale('2048', 'frFR')
if L then
	L['Play while you wait to play!'] = 'Jouez en attendant de jouer !'

	L['Old settings reset to defaults - sorry about that.'] = 'Réglages et scores réinitialisés - désolé.'

	L['MOVES'] = 'COUPS'
	L['SCORE'] = 'SCORE'
	L['BEST'] = 'TOP'

	L['You won!'] = 'Gagné !'
	L['Game over!'] = 'Fini !'
	L['Restart?'] = 'Recommencer ?'
	L['New game'] = 'Nouveau jeu'
	L['Restart'] = 'Recommencer'
	L['Keep playing'] = 'Continuer'
	L['Yes'] = 'Oui'
	L['No'] = 'Non'

	L['Enable keyboard use'] = 'Utiliser le clavier'
	L['Window scale'] = 'Taille de la fenêtre'
	L['Join the numbers and get to the |cFFFF00002048|r tile!'] ='Tentez d\'obtenir le nombre |cFFFF00002048|r !'
end

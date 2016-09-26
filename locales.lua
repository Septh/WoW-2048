
-- EnUS (default locale)
local L = LibStub('AceLocale-3.0'):NewLocale('2048', 'enUS', true)
if not L then return end

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

function plotejarMultiples(senyals, interval, nRepeticionsSimbol, canal)%El primer valor de l'interval ha de ser l'últim instant d'un simbol (per exemple 20, que és l'últim zero de sincronització)
tiledlayout(size(senyals, 2)/4, 1);
for i = 1:size(senyals, 2)/4
    nexttile;
    plotejarSimbols(senyals(:,1+4*(i-1):4*i), interval, nRepeticionsSimbol, canal)
    title("Senyal "+i);
end
end
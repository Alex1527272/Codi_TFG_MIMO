function plotejarSimbols(simbols, interval, nRepeticionsSimbol, canal) %El primer valor de l'interval ha de ser l'últim instant d'un simbol (per exemple 20, que és l'últim zero de sincronització)
plot(interval, real(simbols(interval, canal)),interval, imag(simbols(interval, canal))); 
for i=(interval(1)+floor(nRepeticionsSimbol/2+1)):nRepeticionsSimbol:interval(end)
   xline(i); 
end
yline(0);
legend(["Real" "Imaginaria"])
end
function dataImage = imageToData(image)
    fid = fopen("images/"+image, 'r');
    m = fread(fid, 'uint8');
    fclose(fid);
    dataImage = m;
end
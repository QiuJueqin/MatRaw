function [ Image ] = demosaic_xtrans( Image )
% converts XTrans mosaiced Images into full color RGB images
% by Alexander Fr?hlich - Jan, 2016
% http://alexanderfroehlich.blogspot.com/2016/01/demosaicking-algorithm-for-x-trans.html

[~, ~, Colors] = size(Image);

if Colors == 1 
    Image=SeparateColors(Image);
elseif Colors == 3
    %do nothing
else 
    error 'invalid number of color channels in the image';
end

[Height, Width, ~] = size(Image);

[H_Image,V_Image,D1_Image,D2_Image]=XTrans_to_RGB_G( Image );

H_Image=XTrans_to_RGB_RB(H_Image,'-');
V_Image=XTrans_to_RGB_RB(V_Image,'|');
D1_Image=XTrans_to_RGB_RB(D1_Image,'/');
D2_Image=XTrans_to_RGB_RB(D2_Image,'\');

%Convert to CIELAB and rate
Rate=zeros(Height,Width,4);

x=3:Width-2;
y=3:Height-2;
colorTransform = makecform('srgb2lab');

H_ImageTest = applycform(H_Image, colorTransform);
Rate(y,x,1)=max(sum((H_ImageTest(y,x,:)-H_ImageTest(y,x-1,:)).^2,3),sum((H_ImageTest(y,x,:)-H_ImageTest(y,x+1,:)).^2,3));
clear H_ImageTest;

V_ImageTest = applycform(V_Image, colorTransform);
Rate(y,x,2)=max(sum((V_ImageTest(y,x,:)-V_ImageTest(y-1,x,:)).^2,3),sum((V_ImageTest(y,x,:)-V_ImageTest(y+1,x,:)).^2,3));
clear V_ImageTest;

D1_ImageTest = applycform(D1_Image, colorTransform);
Rate(y,x,3)=max(sum((D1_ImageTest(y,x,:)-D1_ImageTest(y-1,x+1,:)).^2,3),sum((D1_ImageTest(y,x,:)-D1_ImageTest(y+1,x-1,:)).^2,3));
clear D1_ImageTest;

D2_ImageTest = applycform(D2_Image, colorTransform);
Rate(y,x,4)=max(sum((D2_ImageTest(y,x,:)-D2_ImageTest(y-1,x-1,:)).^2,3),sum((D2_ImageTest(y,x,:)-D2_ImageTest(y+1,x+1,:)).^2,3));
clear D2_ImageTest;


%H = fspecial('gaussian',5,2);
H = [0 1 1 1 0; 1 3 3 3 1; 1 3 3 3 1; 1 3 3 3 1; 0 1 1 1 0];
%H=[1 1 1; 1 1 1; 1 1 1];
Rate = imfilter(Rate,H);
Rate=Rate+0.00001;
Rate=Rate.^-2;
Image=(H_Image.*repmat(Rate(:,:,1)./sum(Rate,3),[1,1,3]))+...
      (V_Image.*repmat(Rate(:,:,2)./sum(Rate,3),[1,1,3]))+...
      (D1_Image.*repmat(Rate(:,:,3)./sum(Rate,3),[1,1,3]))+...
      (D2_Image.*repmat(Rate(:,:,4)./sum(Rate,3),[1,1,3]));


Image = AliasCancelling(Image, 2);

end


%%
function [ I_horz, I_vert, I_diag45, I_diag135 ] = XTrans_to_RGB_G( I )

[Height,Width,Colors]=size(I);
I_vert=I;
I_horz=I;
I_diag45=I;
I_diag135=I;
h=[-1,9,9,-1];
%h=[0,1,1,0]/2;

y = 3:3:Height-3;
x = 5:3:Width-4;
I_horz(y,x,2)=(h(1)*I(y,x-2,2) + h(2)*I(y,x-1,2) + h(3)*I(y,x+1,2) + h(4)*I(y,x+2,2))/sum(h);
I_vert(y,x,2)=(2*I(y-1,x,2) + I(y+2,x,2))/3;
I_diag45(y,x,2)=(2*I(y+1,x-1,2) + I(y-2,x+2,2))/3;
I_diag135(y,x,2)=(2*I(y+1,x+1,2) + I(y-2,x-2,2))/3;
       
I_horz(y+1,x,2)=(h(1)*I(y+1,x-2,2) + h(2)*I(y+1,x-1,2) + h(3)*I(y+1,x+1,2) +h(4)*I(y+1,x+2,2))/sum(h);
I_vert(y+1,x,2)=(I(y-1,x,2)+2*I(y+2,x,2))/3;
I_diag45(y+1,x,2)=(2*I(y,x+1,2) + I(y+3,x-2,2))/3;
I_diag135(y+1,x,2)=(2*I(y,x-1,2) + I(y+3,x+2,2))/3;
        
y = 5:3:Height-4;
x = 3:3:Width-3; 
I_vert(y,x,2)=(h(1)*I(y-2,x,2) + h(2)*I(y-1,x,2) + h(3)*I(y+1,x,2) +h(4)*I(y+2,x,2))/sum(h);
I_horz(y,x,2)=(2*I(y,x-1,2)+I(y,x+2,2))/3;
I_diag45(y,x,2)=(2*I(y-1,x+1,2) + I(y+2,x-2,2))/3;
I_diag135(y,x,2)=(2*I(y+1,x+1,2) + I(y-2,x-2,2))/3;
                
I_vert(y,x+1,2)=(h(1)*I(y-2,x+1,2) + h(2)*I(y-1,x+1,2) + h(3)*I(y+1,x+1,2) +h(4)*I(y+2,x+1,2))/sum(h);
I_horz(y,x+1,2)=(I(y,x-1,2)+2*I(y,x+2,2))/3;
I_diag45(y,x+1,2)=(2*I(y+1,x,2) + I(y-2,x+3,2))/3;
I_diag135(y,x+1,2)=(2*I(y-1,x,2) + I(y+2,x+3,2))/3;

end





%%
function [ I ] = XTrans_to_RGB_RB( I ,direction)

w_dir=2;

%d=[1,1,1,1,1];
d=[1,sqrt(2),2,sqrt(5),10];
%d=[1,sqrt(2),2,sqrt(5)5,3].^2;
%d=[1 1 1 1 1];
d1=d(1); d2=d(2); d3=d(3); d4=d(4); d5=d(5);

save=0.001;    


if strcmp(direction,'-')
    h=w_dir; v=1/w_dir; nodir=min(h,v); hv1=nodir; hv2=nodir;
elseif strcmp(direction,'|')
    h=1/w_dir; v=w_dir; nodir=min(h,v); hv1=nodir; hv2=nodir;
elseif strcmp(direction,'/')
    hv1=w_dir; hv2=1/w_dir; nodir=min(hv1,hv2); h=nodir; v=nodir;
elseif strcmp(direction,'\')
    hv1=1/w_dir; hv2=w_dir; nodir=min(hv1,hv2); h=nodir; v=nodir;
else
    h=1; v=1; nodir=min(h,v); hv1=nodir; hv2=nodir;
end

[Height,Width,Colors]=size(I);
Margin=3;
Top=1+Margin;
Bottom=Height-Margin;
Left=1+Margin;
Right=Width-Margin;



for i=1:2
    
    %  if pos==203 || pos==500
    if i==1 % 2,3
        y=8:6:Height-4; x=3:6:Width-4;
    elseif i==2 % 5,0
        y=5:6:Height-4; x=6:6:Width-4;
    end
    A = I(y,x+1,3) - I(y,x+1,2);
    B = I(y+1,x-1,3) - I(y+1,x-1,2);
    C = I(y-1,x-1,3) - I(y-1,x-1,2);
    D = I(y-3,x,3) - I(y-3,x,2);
    E = I(y+3,x,3) - I(y+3,x,2);
    dA = (save + abs(I(y,x,2) - I(y,x+1,2)))*d1/h;
    dB = (save + abs(I(y,x,2) - I(y+1,x-1,2)))*d2/hv1;
    dC = (save + abs(I(y,x,2) - I(y-1,x-1,2)))*d2/hv2;
    dD = (save + abs(I(y,x,2) - I(y-3,x,2)))*d5/v;
    dE = (save + abs(I(y,x,2) - I(y+3,x,2)))*d5/v;
    I(y,x,3) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);
            
    % if pos==305 || pos==002
    if i==1 % 3,5
        y=3:6:Height-4; x=5:6:Width-4;
    elseif i==2 %0,2
        y=6:6:Height-4; x=8:6:Width-4;
    end
    A = I(y+1,x,3) - I(y+1,x,2);
    B = I(y-1,x-1,3) - I(y-1,x-1,2);
    C = I(y-1,x+1,3) - I(y-1,x+1,2);
    D = I(y,x-3,3) - I(y,x-3,2);
    E = I(y,x+3,3) - I(y,x+3,2);
    dA = (save + abs(I(y,x,2) - I(y+1,x,2)))*d1/v;
    dB = (save + abs(I(y,x,2) - I(y-1,x-1,2)))*d2/hv2;
    dC = (save + abs(I(y,x,2) - I(y-1,x+1,2)))*d2/hv1;
    dD = (save + abs(I(y,x,2) - I(y,x-3,2)))*d5/h;
    dE = (save + abs(I(y,x,2) - I(y,x+3,2)))*d5/h;
    I(y,x,3) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);
            



    % if pos==402 || pos==105
    if i==1 % 4,2
        y=4:6:Height-4; x=8:6:Width-4;
    elseif i==2 %1,5
        y=7:6:Height-4; x=5:6:Width-4;
    end
    A = I(y-1,x,3) - I(y-1,x,2);
    B = I(y+1,x+1,3) - I(y+1,x+1,2);
    C = I(y+1,x-1,3) - I(y+1,x-1,2);
    D = I(y,x-3,3) - I(y,x-3,2);
    E = I(y,x+3,3) - I(y,x+3,2);
    dA = (save + abs(I(y,x,2) - I(y-1,x,2)))*d1/v;
    dB = (save + abs(I(y,x,2) - I(y+1,x+1,2)))*d2/hv2;
    dC = (save + abs(I(y,x,2) - I(y+1,x-1,2)))*d2/hv1;
    dD = (save + abs(I(y,x,2) - I(y,x-3,2)))*d5/h;
    dE = (save + abs(I(y,x,2) - I(y,x+3,2)))*d5/h;
    I(y,x,3) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);  
end            


%5,4 if pos==504 || pos==201
y=5:6:Height-4; x=4:6:Width-4;
A = I(y,x-1,3) - I(y,x-1,2);
B = I(y-1,x+1,3) - I(y-1,x+1,2);
C = I(y+1,x+1,3) - I(y+1,x+1,2);
D = I(y-3,x,3) - I(y-3,x,2);
E = I(y+3,x,3) - I(y+3,x,2);
dA = (save + abs(I(y,x,2) - I(y,x-1,2)))*d1/h;
dB = (save + abs(I(y,x,2) - I(y-1,x+1,2)))*d2/hv1;
dC = (save + abs(I(y,x,2) - I(y+1,x+1,2)))*d2/hv2;
dD = (save + abs(I(y,x,2) - I(y-3,x,2)))*d5/v;
dE = (save + abs(I(y,x,2) - I(y+3,x,2)))*d5/v;
I(y,x,3) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);

%2,1 if pos==504 || pos==201
y=8:6:Height-4; x=7:6:Width-4;
A = I(y,x-1,3) - I(y,x-1,2);
B = I(y-1,x+1,3) - I(y-1,x+1,2);
C = I(y+1,x+1,3) - I(y+1,x+1,2);
D = I(y-3,x,3) - I(y-3,x,2);
E = I(y+3,x,3) - I(y+3,x,2);
dA = (save + abs(I(y,x,2) - I(y,x-1,2)))*d1/h;
dB = (save + abs(I(y,x,2) - I(y-1,x+1,2)))*d2/hv1;
dC = (save + abs(I(y,x,2) - I(y+1,x+1,2)))*d2/hv2;
dD = (save + abs(I(y,x,2) - I(y-3,x,2)))*d5/v;
dE = (save + abs(I(y,x,2) - I(y+3,x,2)))*d5/v;
I(y,x,3) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);

%red at blue positions
% 1,2 if pos==102 || pos==405
y=7:6:Height-4; x=8:6:Width-4;
A = I(y-1,x,1) - I(y-1,x,2);
B = I(y+1,x+1,1) - I(y+1,x+1,2);
C = I(y+1,x-1,1) - I(y+1,x-1,2);
D = I(y,x-3,1) - I(y,x-3,2);
E = I(y,x+3,1) - I(y,x+3,2);
dA = (save + abs(I(y,x,2) - I(y-1,x,2)))*d1/v;
dB = (save + abs(I(y,x,2) - I(y+1,x+1,2)))*d2/hv2;
dC = (save + abs(I(y,x,2) - I(y+1,x-1,2)))*d2/hv1;
dD = (save + abs(I(y,x,2) - I(y,x-3,2)))*d5/h;
dE = (save + abs(I(y,x,2) - I(y,x+3,2)))*d5/h;
I(y,x,1) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);

% 4,5 if pos==102 || pos==405
y=4:6:Height-4; x=5:6:Width-4;
A = I(y-1,x,1) - I(y-1,x,2);
B = I(y+1,x+1,1) - I(y+1,x+1,2);
C = I(y+1,x-1,1) - I(y+1,x-1,2);
D = I(y,x-3,1) - I(y,x-3,2);
E = I(y,x+3,1) - I(y,x+3,2);
dA = (save + abs(I(y,x,2) - I(y-1,x,2)))*d1/v;
dB = (save + abs(I(y,x,2) - I(y+1,x+1,2)))*d2/hv2;
dC = (save + abs(I(y,x,2) - I(y+1,x-1,2)))*d2/hv1;
dD = (save + abs(I(y,x,2) - I(y,x-3,2)))*d5/h;
dE = (save + abs(I(y,x,2) - I(y,x+3,2)))*d5/h;
I(y,x,1) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);
            
% 3,2 elseif pos==302 || pos==005
y=3:6:Height-4; x=8:6:Width-4;
A = I(y+1,x,1) - I(y+1,x,2);
B = I(y-1,x-1,1) - I(y-1,x-1,2);
C = I(y-1,x+1,1) - I(y-1,x+1,2);
D = I(y,x-3,1) - I(y,x-3,2);
E = I(y,x+3,1) - I(y,x+3,2);
dA = (save + abs(I(y,x,2) - I(y+1,x,2)))*d1/v;
dB = (save + abs(I(y,x,2) - I(y-1,x-1,2)))*d2/hv2;
dC = (save + abs(I(y,x,2) - I(y-1,x+1,2)))*d2/hv1;
dD = (save + abs(I(y,x,2) - I(y,x-3,2)))*d5/h;
dE = (save + abs(I(y,x,2) - I(y,x+3,2)))*d5/h;
I(y,x,1) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);
            
% 0,5 elseif pos==302 || pos==005
y=6:6:Height-4; x=5:6:Width-4;
A = I(y+1,x,1) - I(y+1,x,2);
B = I(y-1,x-1,1) - I(y-1,x-1,2);
C = I(y-1,x+1,1) - I(y-1,x+1,2);
D = I(y,x-3,1) - I(y,x-3,2);
E = I(y,x+3,1) - I(y,x+3,2);
dA = (save + abs(I(y,x,2) - I(y+1,x,2)))*d1/v;
dB = (save + abs(I(y,x,2) - I(y-1,x-1,2)))*d2/hv2;
dC = (save + abs(I(y,x,2) - I(y-1,x+1,2)))*d2/hv1;
dD = (save + abs(I(y,x,2) - I(y,x-3,2)))*d5/h;
dE = (save + abs(I(y,x,2) - I(y,x+3,2)))*d5/h;
I(y,x,1) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);

% 2,4 if pos==204 || pos==501
y=8:6:Height-4; x=4:6:Width-4;
A = I(y,x-1,1) - I(y,x-1,2);
B = I(y-1,x+1,1) - I(y-1,x+1,2);
C = I(y+1,x+1,1) - I(y+1,x+1,2);
D = I(y-3,x,1) - I(y-3,x,2);
E = I(y+3,x,1) - I(y+3,x,2);
dA = (save + abs(I(y,x,2) - I(y,x-1,2)))*d1/h;
dB = (save + abs(I(y,x,2) - I(y-1,x+1,2)))*d2/hv1;
dC = (save + abs(I(y,x,2) - I(y+1,x+1,2)))*d2/hv2;
dD = (save + abs(I(y,x,2) - I(y-3,x,2)))*d5/v;
dE = (save + abs(I(y,x,2) - I(y+3,x,2)))*d5/v;
I(y,x,1) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);

% 5,1 if pos==204 || pos==501
y=5:6:Height-4; x=7:6:Width-4;
A = I(y,x-1,1) - I(y,x-1,2);
B = I(y-1,x+1,1) - I(y-1,x+1,2);
C = I(y+1,x+1,1) - I(y+1,x+1,2);
D = I(y-3,x,1) - I(y-3,x,2);
E = I(y+3,x,1) - I(y+3,x,2);
dA = (save + abs(I(y,x,2) - I(y,x-1,2)))*d1/h;
dB = (save + abs(I(y,x,2) - I(y-1,x+1,2)))*d2/hv1;
dC = (save + abs(I(y,x,2) - I(y+1,x+1,2)))*d2/hv2;
dD = (save + abs(I(y,x,2) - I(y-3,x,2)))*d5/v;
dE = (save + abs(I(y,x,2) - I(y+3,x,2)))*d5/v;
I(y,x,1) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);

% 2,0 if pos==200 || pos==503
y=8:6:Height-4; x=6:6:Width-4;
A = I(y,x+1,1) - I(y,x+1,2);
B = I(y+1,x-1,1) - I(y+1,x-1,2);
C = I(y-1,x-1,1) - I(y-1,x-1,2);
D = I(y-3,x,1) - I(y-3,x,2);
E = I(y+3,x,1) - I(y+3,x,2);
dA = (save + abs(I(y,x,2) - I(y,x+1,2)))*d1/h;
dB = (save + abs(I(y,x,2) - I(y+1,x-1,2)))*d2/hv1;
dC = (save + abs(I(y,x,2) - I(y-1,x-1,2)))*d2/hv2;
dD = (save + abs(I(y,x,2) - I(y-3,x,2)))*d5/v;
dE = (save + abs(I(y,x,2) - I(y+3,x,2)))*d5/v;
I(y,x,1) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);

% 5,3 if pos==200 || pos==503
y=5:6:Height-4; x=3:6:Width-4;
A = I(y,x+1,1) - I(y,x+1,2);
B = I(y+1,x-1,1) - I(y+1,x-1,2);
C = I(y-1,x-1,1) - I(y-1,x-1,2);
D = I(y-3,x,1) - I(y-3,x,2);
E = I(y+3,x,1) - I(y+3,x,2);
dA = (save + abs(I(y,x,2) - I(y,x+1,2)))*d1/h;
dB = (save + abs(I(y,x,2) - I(y+1,x-1,2)))*d2/hv1;
dC = (save + abs(I(y,x,2) - I(y-1,x-1,2)))*d2/hv2;
dD = (save + abs(I(y,x,2) - I(y-3,x,2)))*d5/v;
dE = (save + abs(I(y,x,2) - I(y+3,x,2)))*d5/v;
I(y,x,1) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD + E./dE)./(1./dA+1./dB+1./dC+1./dD+1./dE);
                        
        
%single green positions

% pos==202 || pos==505 || pos==205 || pos==502
for i=1:4
    if i==1 % 2,2
        y=2:6:Height-2; x=2:6:Width-2;
    elseif i==2 % 5,5
        y=5:6:Height-2; x=5:6:Width-2;
    elseif i==3 % 2,5
        y=2:6:Height-2; x=5:6:Width-2;
    elseif i==4 % 5,2
        y=5:6:Height-2; x=2:6:Width-2;
    end
    A = I(y-1,x,3) - I(y-1,x,2);
    B = I(y+1,x,3) - I(y+1,x,2);
    C = I(y,x-1,3) - I(y,x-1,2);
    D = I(y,x+1,3) - I(y,x+1,2);
    dA = (save + abs(I(y,x,2) - I(y-1,x,2)))/v;
    dB = (save + abs(I(y,x,2) - I(y+1,x,2)))/v;
    dC = (save + abs(I(y,x,2) - I(y,x-1,2)))/h;
    dD = (save + abs(I(y,x,2) - I(y,x+1,2)))/h;
    I(y,x,3) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA+1./dB+1./dC+1./dD);

    A = I(y-1,x,1) - I(y-1,x,2);
    B = I(y+1,x,1) - I(y+1,x,2);
    C = I(y,x-1,1) - I(y,x-1,2);
    D = I(y,x+1,1) - I(y,x+1,2);
    I(y,x,1) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA+1./dB+1./dC+1./dD);
end
            
            
            
%middle block
for i=1:2
    % pos==303 || pos==000
    if i==1 % 3,3
        y=3:6:Height-2; x=3:6:Width-2;
    elseif i==2 % 0,0
        y=6:6:Height-2; x=6:6:Width-2;
    end
    A = I(y-1,x,1) - I(y-1,x,2);
    B = I(y,x+2,1) - I(y,x+2,2);
    C = I(y+2,x+1,1) - I(y+2,x+1,2);
    D = I(y+1,x-1,1) - I(y+1,x-1,2);

    dA = (save + abs(I(y,x,2) - I(y-1,x,2)))*d1/v;
    dB = (save + abs(I(y,x,2) - I(y,x+2,2)))*d3/h;
    dC = (save + abs(I(y,x,2) - I(y+2,x+1,2)))*d4/hv2;
    dD = (save + abs(I(y,x,2) - I(y+1,x-1,2)))*d2/hv1;
    I(y,x,1) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y,x+1,2) - I(y-1,x,2)))*d2/hv2;
    dB = (save + abs(I(y,x+1,2) - I(y,x+2,2)))*d1/h;
    dC = (save + abs(I(y,x+1,2) - I(y+2,x+1,2)))*d3/v;
    dD = (save + abs(I(y,x+1,2) - I(y+1,x-1,2)))*d4/hv1;
    I(y,x+1,1) = I(y,x+1,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y+1,x,2) - I(y-1,x,2)))*d3/v;
    dB = (save + abs(I(y+1,x,2) - I(y,x+2,2)))*d4/hv1;
    dC = (save + abs(I(y+1,x,2) - I(y+2,x+1,2)))*d2/hv2;
    dD = (save + abs(I(y+1,x,2) - I(y+1,x-1,2)))*d1/h;
    I(y+1,x,1) = I(y+1,x,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y+1,x+1,2) - I(y-1,x,2)))*d4/hv2;
    dB = (save + abs(I(y+1,x+1,2) - I(y,x+2,2)))*d2/hv1;
    dC = (save + abs(I(y+1,x+1,2) - I(y+2,x+1,2)))*d1/v;
    dD = (save + abs(I(y+1,x+1,2) - I(y+1,x-1,2)))*d3/h;
    I(y+1,x+1,1) = I(y+1,x+1,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);



    A = I(y-1,x+1,3) - I(y-1,x+1,2);
    B = I(y+1,x+2,3) - I(y+1,x+2,2);
    C = I(y+2,x,3) - I(y+2,x,2);
    D = I(y,x-1,3) - I(y,x-1,2);

    dA = (save + abs(I(y,x,2) - I(y-1,x+1,2)))*d2/hv1;
    dB = (save + abs(I(y,x,2) - I(y+1,x+2,2)))*d4/hv2;
    dC = (save + abs(I(y,x,2) - I(y+2,x,2)))*d3/v;
    dD = (save + abs(I(y,x,2) - I(y,x-1,2)))*d1/h;
    I(y,x,3) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y,x+1,2) - I(y-1,x+1,2)))*d1/v;
    dB = (save + abs(I(y,x+1,2) - I(y+1,x+2,2)))*d2/hv2;
    dC = (save + abs(I(y,x+1,2) - I(y+2,x,2)))*d4/hv1;
    dD = (save + abs(I(y,x+1,2) - I(y,x-1,2)))*d3/h;
    I(y,x+1,3) = I(y,x+1,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y+1,x,2) - I(y-1,x+1,2)))*d4/hv1;
    dB = (save + abs(I(y+1,x,2) - I(y+1,x+2,2)))*d3/h;
    dC = (save + abs(I(y+1,x,2) - I(y+2,x,2)))*d1/v;
    dD = (save + abs(I(y+1,x,2) - I(y,x-1,2)))*d2/hv2;
    I(y+1,x,3) = I(y+1,x,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y+1,x+1,2) - I(y-1,x+1,2)))*d3/v;
    dB = (save + abs(I(y+1,x+1,2) - I(y+1,x+2,2)))*d1/h;
    dC = (save + abs(I(y+1,x+1,2) - I(y+2,x,2)))*d2/hv1;
    dD = (save + abs(I(y+1,x+1,2) - I(y,x-1,2)))*d4/hv2;
    I(y+1,x+1,3) = I(y+1,x+1,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);
    
    
    % pos==003 || pos==300
    if i==1 % 0,3
        y=6:6:Height-2; x=3:6:Width-2;
    elseif i==2 % 3,0
        y=3:6:Height-2; x=6:6:Width-2;
    end
    A = I(y-1,x,3) - I(y-1,x,2);
    B = I(y,x+2,3) - I(y,x+2,2);
    C = I(y+2,x+1,3) - I(y+2,x+1,2);
    D = I(y+1,x-1,3) - I(y+1,x-1,2);

    dA = (save + abs(I(y,x,2) - I(y-1,x,2)))*d1/v;
    dB = (save + abs(I(y,x,2) - I(y,x+2,2)))*d3/h;
    dC = (save + abs(I(y,x,2) - I(y+2,x+1,2)))*d4/nodir;
    dD = (save + abs(I(y,x,2) - I(y+1,x-1,2)))*d2/nodir;
    I(y,x,3) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y,x+1,2) - I(y-1,x,2)))*d2/hv2;
    dB = (save + abs(I(y,x+1,2) - I(y,x+2,2)))*d1/h;
    dC = (save + abs(I(y,x+1,2) - I(y+2,x+1,2)))*d3/v;
    dD = (save + abs(I(y,x+1,2) - I(y+1,x-1,2)))*d4/hv1;
    I(y,x+1,3) = I(y,x+1,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y+1,x,2) - I(y-1,x,2)))*d3/v;
    dB = (save + abs(I(y+1,x,2) - I(y,x+2,2)))*d4/hv1;
    dC = (save + abs(I(y+1,x,2) - I(y+2,x+1,2)))*d2/hv2;
    dD = (save + abs(I(y+1,x,2) - I(y+1,x-1,2)))*d1/h;
    I(y+1,x,3) = I(y+1,x,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y+1,x+1,2) - I(y-1,x,2)))*d4/hv2;
    dB = (save + abs(I(y+1,x+1,2) - I(y,x+2,2)))*d2/hv1;
    dC = (save + abs(I(y+1,x+1,2) - I(y+2,x+1,2)))*d1/v;
    dD = (save + abs(I(y+1,x+1,2) - I(y+1,x-1,2)))*d3/h;
    I(y+1,x+1,3) = I(y+1,x+1,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    A = I(y-1,x+1,1) - I(y-1,x+1,2);
    B = I(y+1,x+2,1) - I(y+1,x+2,2);
    C = I(y+2,x,1) - I(y+2,x,2);
    D = I(y,x-1,1) - I(y,x-1,2);

    dA = (save + abs(I(y,x,2) - I(y-1,x+1,2)))*d2/hv1;
    dB = (save + abs(I(y,x,2) - I(y+1,x+2,2)))*d4/hv2;
    dC = (save + abs(I(y,x,2) - I(y+2,x,2)))*d3/v;
    dD = (save + abs(I(y,x,2) - I(y,x-1,2)))*d1/h;
    I(y,x,1) = I(y,x,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y,x+1,2) - I(y-1,x+1,2)))*d1/v;
    dB = (save + abs(I(y,x+1,2) - I(y+1,x+2,2)))*d2/hv2;
    dC = (save + abs(I(y,x+1,2) - I(y+2,x,2)))*d4/hv1;
    dD = (save + abs(I(y,x+1,2) - I(y,x-1,2)))*d3/h;
    I(y,x+1,1) = I(y,x+1,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y+1,x,2) - I(y-1,x+1,2)))*d4/hv1;
    dB = (save + abs(I(y+1,x,2) - I(y+1,x+2,2)))*d3/h;
    dC = (save + abs(I(y+1,x,2) - I(y+2,x,2)))*d1/v;
    dD = (save + abs(I(y+1,x,2) - I(y,x-1,2)))*d2/hv2;
    I(y+1,x,1) = I(y+1,x,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);

    dA = (save + abs(I(y+1,x+1,2) - I(y-1,x+1,2)))*d3/v;
    dB = (save + abs(I(y+1,x+1,2) - I(y+1,x+2,2)))*d1/h;
    dC = (save + abs(I(y+1,x+1,2) - I(y+2,x,2)))*d2/hv1;
    dD = (save + abs(I(y+1,x+1,2) - I(y,x-1,2)))*d4/hv2;
    I(y+1,x+1,1) = I(y+1,x+1,2) + (A./dA + B./dB + C./dC + D./dD)./(1./dA + 1./dB + 1./dC + 1./dD);
    
    
    
end
         

end


%%
function [Image] = AliasCancelling(Image,Loops)

if Loops==0
    return;
end


for i=1:Loops
    Image(:,:,2)=(medfilt2(Image(:,:,2)-Image(:,:,3))+medfilt2(Image(:,:,2)-Image(:,:,1))+Image(:,:,1)+Image(:,:,3))/2;
    Image(:,:,1)=Image(:,:,2)+medfilt2(Image(:,:,1)-Image(:,:,2));
    Image(:,:,3)=Image(:,:,2)+medfilt2(Image(:,:,3)-Image(:,:,2));
end
end


%%
function [ Image ] = SeparateColors( FlatImage )

[Height,Width,Colors]=size(FlatImage);

X=zeros(3,3);
Y=zeros(3,3);
for i=0:2
    for j=0:2
        temp(:,:,1)=FlatImage(3+i:3:end-4+i,3+j:3:end-4+j);
        temp(:,:,2)=FlatImage(4+i:3:end-4+i,3+j:3:end-4+j);
        temp(:,:,3)=FlatImage(3+i:3:end-4+i,4+j:3:end-4+j);
        temp(:,:,4)=FlatImage(4+i:3:end-4+i,4+j:3:end-4+j);
        X(i+1,j+1)=mean(mean(std(temp,0,3)));

    end
end
X=X-min(min(X));
[r,c]=find(X==0);

FlatImage=FlatImage(r:end,c:end,:);
[Height,Width,Colors]=size(FlatImage);

B = [ 0 1 0 0 0 0;
      0 0 0 1 0 1;
      0 1 0 0 0 0;
      0 0 0 0 1 0;
      1 0 1 0 0 0;
      0 0 0 0 1 0];
R = transpose(B);
G = (R+B)*(-1)+1;
XTransMask=repmat(cat(3,R,G,B),ceil(Height/6),ceil(Width/6));

Image(:,:,1)=FlatImage.*XTransMask(1:Height,1:Width,1);
Image(:,:,2)=FlatImage.*XTransMask(1:Height,1:Width,2);
Image(:,:,3)=FlatImage.*XTransMask(1:Height,1:Width,3);



end
%% Channel Estimation_for LS/DFT Channel Estimation with linear/Spline interpolation

% clear all;
close all;
clc
clf                                                                        % �����ǰͼ�񴰿�

%% Paramter Setting
Nfft = 32;                                                                 % FFT����32
Ng = Nfft/8;                                                               % ѭ��ǰ׺����8
Nofdm = Nfft + Ng;                                                         % һ��OFDM�����ܹ���32+8=40��
Nsym = 100;                                                                % OFDM����ĿΪ100��
Nps = 4;                                                                   % ��Ƶ���4
Np = Nfft/Nps;                                                             % ��Ƶ��8
Nbps = 4;
M = 2^Nbps;                                                                % ÿ�����ѵ��ƣ����ŵ�λ��16

% mod_object = modem.qammod('M',M,'SymbolOrder','gray');
% ���Ʋ���,modem.qammod�Ѿ���matlab�߼��汾ɾ��,ֱ��ʹ��qammod���Ƽ���
% demod_object = modem.qamdemod('M',M,'SymbolOrder','gray');              
% �������,modem,qamdemod�Ѿ���matlab�߼��汾ɾ��,ֱ��ʹ��deqammod�������

Es = 1;                                                                    % �ź�����
A = sqrt(3/2/(M-1)*Es);                                                    % QAM��һ������ 
SNR = 30;                                                                  % �����30dB
sq2 = sqrt(2);                                                             % ����2
MSE = zeros(1,6);                                                          % MSE��ʼ��
nose = 0;                                                                  % BER�ۼӳ�ʼֵ

%% Transmit Data Generation
for nsym = 1:Nsym
    Xp = 2*(randn(1,Np)>0)-1;                                              % ��Ƶ����                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  % ���ɵ�Ƶ����(ÿ��Ԫ��Ϊ1��-1��ɵ�������)
    % msgint = randint(1,Nfft-Np,M);                                       % randint �����Ѿ���matlab�߼��汾ɾ��
    msgint = randi([0,M-1],[1,Nfft-Np]);                                   % ���ɱ������ݣ�bit generation��
    % Data = A*modulate(mod_object,msgint)      
    % ���ò�����msgint����QAM���ƣ����������÷��Ѿ���matlab�߼���ɾ��
    Data = A*qammod(msgint,M,'gray');                                      % QAM����
    ip = 0;                                                                % ���������Ƶ�Ƶ������
    pilot_loc = [];                                                        % ��Ƶλ��
    for k = 1:Nfft
        if mod(k,Nps)==1
            X(k) = Xp(floor(k/Nps)+1);                                     % ����Ƶ���Ų���X����
            pilot_loc = [pilot_loc k];                                     % ��¼��Ƶ���ŵ�λ��
            ip = ip + 1;                                                   % ��Ƶ��������+1
        else
            X(k) = Data(k-ip);                                             % �������ݷ���
        end
    end   

%% IFFT And Add CP
    x = ifft(X,Nfft);                                                      % �Խ�Ƶ�����X�任��ʱ��
    xt = [x(Nfft-Ng+1:Nfft) x];                                            % ����ѭ��ǰ׺��������ѭ��ǰ׺��Ŀ�����ز��ŵ�����ǰ�棩

%% Channel Parameters
    h = [(randn+1i*randn) (randn+1i*randn)/2];                             % ����һ��2��ͷ���ŵ�ģ��
    H = fft(h,Nfft);                                                       % �ŵ���ʱ���ʾ
    ch_length = length(h);                                                 % ��ʵ�ŵ����ŵ�����
    H_power_dB = 10*log10(abs(H.*conj(H)));                                % ע�⺯����log10(x),dB��10log10(����),����Ĺ��ʵ�λΪW

%% Go Through The Channel
    y_channel = conv(xt,h);                                                % ͨ���ŵ�֮����ź�
    yt = awgn(y_channel,SNR,'measured');                                   % ���Ӹ�˹������

%% Remove CP and FFT
    y = yt(Ng+1:Nofdm);                                                    % �Ƴ�ѭ��ǰ׺
    Y = fft(y);                                                            % ��ʱ�����y�任��Ƶ��

%% LS And MMSE Channel Eatimation
    for m = 1:3
        if m == 1
           H_est = LS_CE(Y,Xp,pilot_loc,Nfft,Nps,'linear');                % �������Բ�ֵ��LS�ŵ�����
           method = 'LS-linear';
        elseif m == 2
               H_est = LS_CE(Y,Xp,pilot_loc,Nfft,Nps,'spline');            % ����������ֵ��LS�ŵ�����
               method = 'LS-spline';
        else
               H_est = MMSE_CE(Y,Xp,pilot_loc,Nfft,Nps,h,SNR);
               method = 'MMSE';                                            % MMSE �ŵ�����
        end

    H_est_power_dB = 10*log10(abs(H_est.*conj(H_est)));                    % ���Ƶ��ŵ�����
    h_est = ifft(H_est);                                                   % ���Ƶ��ŵ���Ӧ��ʱ���ʾ

%% DFT_based Channel Estimation
    h_DFT = h_est(1:ch_length);
    H_DFT = fft(h_DFT,Nfft);                                               % ����DFT���ŵ�����
    H_DFT_power_dB = 10*log10(abs(H_DFT.*conj(H_DFT)));                    % ����DFT���ŵ����ƹ��Ƴ����ŵ�����

    if nsym == 1
        subplot(319+2*m),plot(H_power_dB,'b');                             % 321 323 325�ָ�figure����3��2�е���ͼ
        hold on;                                                           % ��135��ͼ���Ȼ���ʵ�ŵ�������ͼ���ٻ����Ƴ����ŵ�������ͼ
        plot(H_est_power_dB,'r:+');
        legend('True Channel',method);
   
        subplot(320+2*m),plot(H_power_dB,'b');                             % 322 324 326�ָ�figure����Ϊ3��2�е���ͼ
        hold on;                                                           % ��246��ͼ���Ȼ���ʵ�ŵ�������ͼ���ٻ�DFT�Ż�����Ƴ����ŵ�����ͼ
        plot(H_DFT_power_dB,'r:+');
        legend('True Channel',[method ' with DFT']);
    end

    MSE(m) = MSE(m) + (H-H_est)*(H-H_est)';                                % ��¼ÿ�ַ�����Ӧ��MSEֵ�ۼӣ�3�ֱַ��Ӧ��LS-linear LS-spine MMSE��
    MSE(m+3)= MSE(m+3) + (H-H_DFT)*(H-H_DFT)';                             % ��¼DFT������Ķ�Ӧ��MSEֵ�ۼӣ�3�ֱַ��Ӧ��LS-linear-DFT LS-spline-DFT MMSE-DFT��
    end
    
    Y_eq = Y./H_est;                                                       % ZF����
    ip = 0;
    
    for k = 1:Nfft
        if mod(k,Nps)==1
            ip = ip + 1;
        else
            Data_extracted(k-ip)=Y_eq(k);                                  % ȡ���ָ����������
        end
    end
    
    % msg_detected = demodulate(demod_object,Data_extracted/A);
    % �����Ҫע���������÷��Ѿ����°汾matlabɾ����
    msg_detected = qamdemod(Data_extracted/A,M,'gray');                    % ���������
    nose = nose + sum(msg_detected ~= msgint);                             % ��BER
    MSEs = MSE/(Nfft*Nsym);
end
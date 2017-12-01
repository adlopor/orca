classdef SVOREX < Algorithm
    %SVOREX Support Vector for Ordinal Regression (Explicit constraints)
    %   This class derives from the Algorithm Class and implements the
    %   SVOREX method. This class uses SVOREX implementation by
    %   W. Chu et al (http://www.gatsby.ucl.ac.uk/~chuwei/svor.htm)
    %
    %   SVOREX methods:
    %      runAlgorithm               - runs the corresponding algorithm,
    %                                   fitting the model and testing it in a dataset.
    %      train                      - Learns a model from data
    %      test                       - Performs label prediction
    %
    %   References:
    %     [1] P.A. Gutiérrez, M. Pérez-Ortiz, J. Sánchez-Monedero,
    %         F. Fernández-Navarro and C. Hervás-Martínez
    %         Ordinal regression methods: survey and experimental study
    %         IEEE Transactions on Knowledge and Data Engineering, Vol. 28. Issue 1
    %         2016
    %         http://dx.doi.org/10.1109/TKDE.2015.2457911
    %     [2] W. Chu and S. S. Keerthi, Support Vector Ordinal Regression,
    %         Neural Computation, vol. 19, no. 3, pp. 792–815, 2007.
    %         http://10.1162/neco.2007.19.3.792
    %
    %   This file is part of ORCA: https://github.com/ayrna/orca
    %   Original authors: Pedro Antonio Gutiérrez, María Pérez Ortiz, Javier Sánchez Monedero
    %   Citation: If you use this code, please cite the associated paper http://www.uco.es/grupos/ayrna/orreview
    %   Copyright:
    %       This software is released under the The GNU General Public License v3.0 licence
    %       available at http://www.gnu.org/licenses/gpl-3.0.html
    
    properties
        
        parameters;
        
        name_parameters = {'C', 'k'};
    end
    
    methods
        function obj = SVOREX(kernel)
            %SVOREX constructs an object of the class SVR and sets its default
            %   characteristics
            %   OBJ = SVOREX(KERNEL) builds SVR with KERNEL as kernel function
            obj.name = 'Support Vector for Ordinal Regression (Explicit constraints)';
            if(nargin ~= 0)
                obj.kernelType = kernel;
            else
                obj.kernelType = 'rbf';
            end
        end
        
        %TODO: Fix train/test API
        function obj = defaultParameters(obj)
            %DEFAULTPARAMETERS It assigns the parameters of the algorithm
            %   to a default value.
            % cost
            obj.parameters.C =  10.^(-3:1:3);
            % kernel width
            obj.parameters.k = 10.^(-3:1:3);
        end
        
        function [mInf] = runAlgorithm(obj, train, test, parameters)
            %RUNALGORITHM runs the corresponding algorithm, fitting the
            %model and testing it in a dataset.
            %   mInf = RUNALGORITHM(OBJ, TRAIN, TEST, PARAMETERS) learns a
            %   model with TRAIN data and PARAMETERS as hyper-parameter
            %   values for the method. Test the generalization performance
            %   with TRAIN and TEST data and returns predictions and model
            %   in mInf structure.
            addpath(fullfile('Algorithms','SVOREX'));
            
            param.C = parameters(1);
            param.k = parameters(2);
            
            c1 = clock;
            [model,mInf.projectedTest,mInf.projectedTrain, mInf.trainTime, mInf.testTime] = obj.train(train,test,param);
            c2 = clock;
            mInf.trainTime = etime(c2,c1);
            
            mInf.predictedTrain = obj.assignLabels(mInf.projectedTrain, model.thresholds);
            
            c1 = clock;
            [mInf.projectedTest, mInf.predictedTest] = obj.test(test.patterns, model);
            c2 = clock;
            mInf.testTime = etime(c2,c1);
            mInf.model = model;
            
            rmpath(fullfile('Algorithms','SVOREX'));
        end
        
        function [model, projectedTest, projectedTrain, trainTime, testTime] = train(obj, train, test, parameters)
            %TRAIN trains the model for the SVOREX method with TRAIN data and
            %vector of parameters PARAMETERS. Return the learned model.
            [projectedTest, alpha, thresholds, projectedTrain, trainTime, testTime] = svorex([train.patterns train.targets],[test.patterns test.targets],parameters.k,parameters.C,0,0,0);
            model.projection = alpha;
            model.thresholds = thresholds;
            model.parameters = parameters;
            model.algorithm = 'SVOREX';
            model.train = train.patterns;
            
        end
        
        function [projected, predicted] = test(obj, test, model)
            %TEST predict labels of TEST patterns labels using MODEL.            
            kernelMatrix = computeKernelMatrix(model.train',test','rbf',model.parameters.k);
            projected = model.projection*kernelMatrix;
            
            predicted = assignLabels(obj, projected, model.thresholds);            
        end
        
        function predicted = assignLabels(obj, projected, thresholds)            
            numClasses = size(thresholds,2)+1;
            %TEST assign the labels from projections and thresholds
            project2 = repmat(projected, numClasses-1,1);
            project2 = project2 - thresholds'*ones(1,size(project2,2));
            
            % Asignation of the class
            % f(x) = max {Wx-bk<0} or Wx - b_(K-1) > 0
            wx=project2;
            
            % The procedure for that is the following:
            % We assign the values > 0 to NaN
            wx(wx(:,:)>0)=NaN;
            
            % Then, we choose the biggest one.
            [maximum,predicted]=max(wx,[],1);
            
            % If a max is equal to NaN is because Wx-bk for all k is >0, so this
            % pattern belongs to the last class.
            predicted(isnan(maximum(:,:)))=numClasses;
            
            predicted = predicted';
        end
        
    end
    
    
end


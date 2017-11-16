
#include "svm-brdg.h"
#include "svm.h"

extern "C" {
    
    svm_problem* create_problem(Sample *samples, int length, int sampleCount) {
        svm_problem *prob = new svm_problem();
        
        prob->l = sampleCount;
        prob->x = new svm_node*[sampleCount];
        prob->y = new double[sampleCount];
        
        for(int i = 0 ; i < sampleCount ; i++) {
            prob->y[i] = samples[i].positive ? 1 : 0;
            prob->x[i] = new svm_node[length+1];
            
            int j;
            for(j = 0 ; j < length ; j++) {
                prob->x[i][j].index = j;
                prob->x[i][j].value = samples[i].elements[j];
            }
            prob->x[i][j].index = -1;
        }
        return prob;
    }
    
    void destroy_problem(svm_problem* prob, int length, int sampleCount) {
        for(int i = 0 ; i < sampleCount ; i++) {
            delete prob->x[i];
        }
        
        delete[] prob->x;
        delete[] prob->y;
        delete prob;
    }
    
    svm_model* train(svm_problem *prob, double C, double gamma) {
        
        svm_parameter param;
        param.svm_type = C_SVC;
//        param.kernel_type = LINEAR;
        param.kernel_type = RBF;
        param.degree = 3;
        param.gamma = gamma;
        param.coef0 = 0;
        param.nu = 0.5;
        param.cache_size = 128;
        param.C = C;
        param.eps = 1e-3;
        param.p = 0.1;
        param.shrinking = 1;
        param.probability = 0;
        param.nr_weight = 0;
        
        svm_model *model = svm_train(prob, &param);
        
        return model;
    }
    
    bool predict(svm_model *model, Sample sample) {

        svm_node nodes[sample.length+1];
        
        int i;
        for(i = 0 ; i < sample.length ; i++) {
            nodes[i].index = i;
            nodes[i].value = sample.elements[i];
        }
        nodes[i].index = -1;
        
        double r = svm_predict(model, nodes);
        return r > 0;
    }
    
    void destroy_model(svm_model* model) {
        svm_free_and_destroy_model(&model);
    }
}

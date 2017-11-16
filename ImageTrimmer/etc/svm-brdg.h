
#ifndef svm_brdg_h
#define svm_brdg_h

#include "svm.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C"{
#endif
    typedef struct {
        double *elements;
        int length;
        bool positive;
    } Sample;
    
    struct svm_problem* create_problem(Sample *samples, int length, int sampleCount);
    void destroy_problem(struct svm_problem* prob, int length, int sampleCount);
    
    struct svm_model* train(struct svm_problem *prob, double C, double gamma);
    bool predict(struct svm_model *model, Sample sample);
    void destroy_model(struct svm_model *model);

#ifdef __cplusplus
}
#endif

#endif /* svm_brdg_h */

import pandas as pd
import numpy as np
import random
from sklearn.model_selection import train_test_split
from fancyimpute import KNN, SimpleFill
import gc
for days in list([100]):
    seq1 = []
    seq2 = []
    dualseqs = []
    x = []
    y = []
    dualseq_demographic = []
    dualseq_without_demographic = []

    # create onehot vectors
    d400 = pd.read_csv('/Users/kanes/DSCA-Net/drug_data/lw_drug_use_400.csv')
    d400 = pd.get_dummies(d400, columns=['drug']) # onehot for drug
    d400_group = d400.groupby(['hadm_id', 'startdate'], as_index=False).sum()
    d400_group_bin = pd.DataFrame(d400_group.iloc[:, 2:] > 0, dtype=int) #convert to binary
    d400_group_bin_2 = pd.concat([d400_group.iloc[:, 0:2], d400_group_bin], axis=1)

    dfd_raw = pd.read_csv('/Users/kanes/DSCA-Net/drug_data/lw_dataset_%d.csv' % days)
    dfd_drug = pd.DataFrame(dfd_raw.iloc[:,0:2])
    dfd_drug = pd.merge(dfd_drug, d400_group_bin_2) #to merge after impute to save computing time
    dfd_drug = dfd_drug.drop(columns=['startdate'])

    dfd_raw = dfd_raw.drop(columns=['startdate'])
    dfd = pd.get_dummies(dfd_raw, columns=['gender', 'religion', 'language', 'marital_status', 'ethnicity']) # onehot for demo
    dfd.to_csv('/Users/kanes/DSCA-Net/drug_data/lw_dataset_onehot_%d.csv' % days, index=False)


    # impute
    dfd = pd.read_csv('/Users/kanes/DSCA-Net/drug_data/lw_dataset_onehot_%d.csv' % days)
    for i in range(dfd.columns.shape[0]):
        print(days, 'days:', i, dfd.columns[i])
    dfdv = np.array(dfd.values, dtype=float)
    dfdcolumns = dfd.columns
    partsize = 5000
    partsnum = int(dfdv.shape[0]/partsize)
    dfdshape = dfdv.shape
    dfdimp = []
    dfdfinal = []
    del dfd
    gc.collect()
    print('sum %d parts' % partsnum)
    for i in range(partsnum):
        part = []
        if i+1 == partsnum:
            part = dfdv[i*partsize:]
        else:
            part = dfdv[i*partsize:(i+1)*partsize]
        part = KNN(k=10, verbose=False).fit_transform(part)
        for row in part:
            dfdimp.append(row)
        dfdfinal = dfdimp
        dfdfinal = np.array(dfdfinal)
        dfdimpute = pd.DataFrame(dfdfinal, columns=dfdcolumns)
        for col in dfdimpute.columns:
            if dfdimpute[col].isnull().sum() != 0:
                print('error', col, dfdimpute[col].isnull().sum())
        # np.save('/Users/kanes/DSCA-Net/drug_data/knnimpute_dfdfinal_%d.npy' % days, dfdfinal)
        print('part %d done' % (i+1))
        print('current shape:',dfdfinal.shape)
    dfdimpute = pd.concat([dfd_drug, dfdimpute.iloc[:,1:]], axis=1)

    dfdimpute.to_csv('/Users/kanes/DSCA-Net/drug_data/lw_dataset_onehot_knnimpute_%d.csv' % days, index=False)    
    print('impute finish!!!')


    # make dataset seqsdown
    dfhd = pd.read_csv('/Users/kanes/DSCA-Net/drug_data/hadm_days_%s.csv' % days)
    dfdimpute = pd.read_csv('/Users/kanes/DSCA-Net/drug_data/lw_dataset_onehot_knnimpute_%d.csv' % days)

    # # # Uncomment below to adjust the input data
    # # leave out physical exam and demo
    # dfdimpute = dfdimpute.iloc[:, :401]

    # # leave out physical exam 
    # dfdimpute = dfdimpute.iloc[:, :431] 

    # # leave out demo 
    # dfdimpute = dfdimpute.iloc[:, :401]   
    # dfdimpute_p = dfdimpute.iloc[:, 431:] 
    # dfdimpute = pd.concat([dfdimpute, dfdimpute_p], axis=1) 

    print(days, dfdimpute.values.shape)
    for i in range(dfdimpute.columns.shape[0]):
        print(i, dfdimpute.columns[i])
    for hid in dfhd.values[:, 0]:
        tem = dfdimpute[dfdimpute['hadm_id'] == hid].values
        hdays = tem.shape[0]
        if tem.shape[0] != hdays:
            print('error')
        hy = tem[:, 1:401]
        for i in hy:
            if sum(i) == 0:
                print('all 0')
        y_ = []
        for j in range(hdays):
            if j + 1 == hdays:
                y_.append(np.zeros(hy.shape[1], dtype=int))
            else:
                y_.append(hy[j + 1])
        y.append(np.array(y_[:-1]))
        dualseqs.append(tem[:-1, 1:])
    dualseqs = np.array(dualseqs)
    y = np.array(y)
    print(y[0].shape)
    print(dualseqs[0].shape)
    sumdays = 0
    for p in y:
        print(p.shape)
        sumdays += p.shape[0]
        for d in p:
            if sum(d) == 0:
                print('all 0')
    print('sumdays:', sumdays)
    np.save('/Users/kanes/DSCA-Net/drug_data/dualseqs_down_%d.npy' % days, dualseqs)
    np.save('/Users/kanes/DSCA-Net/drug_data/seqy_down_%d.npy' % days, y)
    print(days, 'save!')

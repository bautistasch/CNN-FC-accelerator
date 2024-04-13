import tensorflow as tf
from tensorflow.keras import layers, models
import matplotlib.pyplot as plt
import numpy as np

def gen_weight_map_cnn(weights):
    with open('sim/kernel_bufferCNN_init.mem', 'w') as f:
        for weight in weights: 
            weight = np.round(weight).astype(np.int8)
            rows = weight.shape[0]
            cols = weight.shape[1]
            channels = weight.shape[2]
            filters = weight.shape[3]
            for filter_ in range(filters):
                for channel in range(channels):
                    for i in range(rows):
                        for j in range(cols):
                            if weight[i, j, channel, filter_] < 0:
                                positive_value = weight[i, j, channel, filter_] & 0xFF
                                f.write(format(positive_value, '02x') + '\n')
                            else:
                                f.write(format(weight[i, j, channel, filter_], '02x') + '\n')

def gen_bias_map_cnn(weights): 
    with open('sim/bias_bufferCNN_init.mem', 'w') as f:
        for weight in weights:
            weight = np.round(weight).astype(np.int32)
            for i in range(weight.shape[0]):
                if weight[i] < 0:
                    positive_value = weight[i] & 0xFFFFFFFF
                    f.write(format(positive_value, '08x') + '\n')
                else:
                    f.write(format(weight[i], '08x') + '\n')

def mem_init(a):
    a[a < -128] = -128
    a[a > 127] = 127
    a = np.round(a).astype(np.int8)
    ifmap = np.zeros((a.shape[0], a.shape[1]), dtype=np.int8)
    with open('sim/ram_init.mem', 'w') as f:
        for i in range(a.shape[0]):
            for j in range(a.shape[1]):
                if a[i, j, 0] < 0:
                    positive_value = a[i, j, 0] & 0xFF
                    ifmap[i,j] = positive_value
                    f.write(format(positive_value, '02x') + '\n')
                else:
                    ifmap[i,j] = a[i, j, 0]
                    f.write(format(a[i, j, 0], '02x') + '\n')
        for i in range(int(65536 - a.shape[0]*a.shape[1])):
            f.write(format(0, '02x') + '\n')
    return ifmap


# M = 2**(-n) * M0 
def get_M_shifter(M):
    error_list = [float('inf')] 
    n_list = [float('inf')]
    M0_list = [float('inf')]
    for M0 in np.arange(0.5, 1, step=2**(-8)):
        n = np.round(-np.log2(M/M0))
        err = np.abs(M - 2**(-n) * M0 )
        if err < min(error_list):
            error_list.insert(0, err)
            n_list.insert(0, n)
            M0_list.insert(0, M0)
            if len(error_list) == 10:
                del error_list[9]
                del n_list[9]
                del M0_list[9]

    return n_list[0][0], M0_list[0]*2**8

def gen_n_frac_map_cnn(n_frac_cnn): 
    with open('sim/n_frac_bufferCNN_init.mem', 'w') as f:
        for we in n_frac_cnn:
            for i in range(2):
                tmp = np.round(we[i]).astype(np.uint8)
                f.write(format(tmp, '02x') + '\n')


def gen_cnn_struct(structs, init_add):
    a = np.zeros(14*len(structs), dtype=np.int8)
    for i, struct in enumerate(structs):
        a[i*14] = struct[0]
        #print(f'rn_buffer[{init_add + i*14}] = {struct[0]}; last_stage') # last_stage

        a[i*14 + 1] = struct[1]
        #print(f'rn_buffer[{init_add + 1 + i*14}] = {struct[1]}; amount_channels')  # amount_channels

        a[i*14 + 2] = struct[2]
        #print(f'rn_buffer[{init_add + 2 + i*14}] = {struct[2]}; kernel_size') # kernel_size

        a[i*14 + 3] = struct[3]
        #print(f'rn_buffer[{init_add + 3 + i*14}] = {struct[3]}; stride') # stride

        a[i*14 + 4] = struct[4]
        #print(f'rn_buffer[{init_add + 4 + i*14}] = {struct[4]}; if_size') # if_size

        a[i*14 + 5] = struct[5]
        #print(f'rn_buffer[{init_add + 5 + i*14}] = {struct[5]}; kernel_size_2') # kernel_size_2

        a[i*14 + 6] = np.uint16(struct[6]) & 0x00FF
        #print(f'rn_buffer[{init_add + 6 + i*14}] = {np.uint16(struct[6]) & 0x00FF}; ifsize_2') # ifsize_2
        a[i*14 + 7] = (np.uint16(struct[6]) >> 8) & 0x00FF
        #print(f'rn_buffer[{init_add + 7 + i*14}] = {(np.uint16(struct[6]) >> 8) & 0x00FF}; ifsize_2')

        a[i*14 + 8] = struct[7]
        #print(f'rn_buffer[{init_add + 8 + i*14}] = {struct[7]}; amount_filters') # amount_filters

        a[i*14 + 9] = struct[8]
        #print(f'rn_buffer[{init_add + 9 + i*14}] = {struct[8]}; of_size') # of_size

        a[i*14 + 10] = np.uint16(struct[9]) & 0x00FF
        #print(f'rn_buffer[{init_add + 10 + i*14}] = {np.uint16(struct[9]) & 0x00FF}; ofsize_2') # ofsize_2
        a[i*14 + 11] = (np.uint16(struct[9]) >> 8) & 0x00FF
        #print(f'rn_buffer[{init_add + 11 + i*14}] = {(np.uint16(struct[9]) >> 8) & 0x00FF}; ofsize_2')

        a[i*14 + 12] = np.uint16(struct[10]) & 0x00FF
        #print(f'rn_buffer[{init_add + 12 + i*14}] = {np.uint16(struct[10]) & 0x00FF}; of_offset') # of_offset
        a[i*14 + 13] = (np.uint16(struct[10]) >> 8) & 0x00FF
        #print(f'rn_buffer[{init_add + 13 + i*14}] = {(np.uint16(struct[10]) >> 8) & 0x00FF}; of_offset')

        #print('// ########')

    rn_bufferCNN_init(a)

def rn_bufferCNN_init(a):
    a = a.astype(np.int8)
    with open('sim/rn_bufferCNN_init.mem', 'w') as f:
        for i in range(a.shape[0]):
            if a[i] < 0:
                positive_value = a[i] & 0xFF
                f.write(format(positive_value, '02x') + '\n')
            else:
                f.write(format(a[i], '02x') + '\n')

###### FC ######

def gen_weight_map_fc(weights, channels_last_cnn): 
    with open('sim/kernel_bufferFC_init.mem', 'w') as f:
        for i, weight in enumerate(weights):
            weight[weight < -128] = -128
            weight[weight > 127] = 127
            weight = np.round(weight).astype(np.int8)
            if i == 0:
                for j in range(weight.shape[1]):
                    for ch in range(channels_last_cnn):
                        for i in np.arange(ch, weight.shape[0], step=3):
                            if weight[i, j] < 0:
                                positive_value = weight[i, j] & 0xFF
                                f.write(format(positive_value, '02x') + '\n')
                            else:
                                f.write(format(weight[i, j], '02x') + '\n')  
            else:
                for j in range(weight.shape[1]):
                    for i in range(weight.shape[0]):
                        if weight[i, j] < 0:
                            positive_value = weight[i, j] & 0xFF
                            f.write(format(positive_value, '02x') + '\n')
                        else:
                            f.write(format(weight[i, j], '02x') + '\n')       


def gen_bias_map_fc(weights): 
    with open('sim/bias_bufferFC_init.mem', 'w') as f:
        for weight in weights:
            weight = np.round(weight).astype(np.int32)
            for i in range(weight.shape[0]):
                if weight[i] < 0:
                    positive_value = weight[i] & 0xFFFFFFFF
                    f.write(format(positive_value, '08x') + '\n')
                else:
                    f.write(format(weight[i], '08x') + '\n')


def gen_fc_struct(structs, init_add):
    a = np.zeros(11*len(structs), dtype=np.int8)
    for i, struct in enumerate(structs):
        a[i*11] = np.uint16(struct[0]) & 0x00FF
        a[i*11 + 1] = (np.uint16(struct[0]) >> 8) & 0x00FF
        #print(f'rn_buffer[{init_add + i*10}] = {struct[0]};') # cant_inputs

        a[i*11 + 2] = np.uint16(struct[1]) & 0x00FF
        #print(f'rn_buffer[{init_add + 1 + i*10}] = {np.uint16(struct[1]) & 0x00FF};')  # iters_per_neuron
        a[i*11 + 3] = (np.uint16(struct[1]) >> 8) & 0x00FF
        #print(f'rn_buffer[{init_add + 2 + i*10}] = {(np.uint16(struct[1]) >> 8) & 0x00FF};')

        a[i*11 + 4] = struct[2]
        #print(f'rn_buffer[{init_add + 3 + i*10}] = {struct[2]};') # modulo

        a[i*11 + 5] = struct[3]
        #print(f'rn_buffer[{init_add + 4 + i*10}] = {struct[3]};') # cant_neurons

        a[i*11 + 6] = struct[4]
        #print(f'rn_buffer[{init_add + 5 + i*10}] = {struct[4]};') # last

        a[i*11 + 7] = np.uint16(struct[5]) & 0x00FF
        #print(f'rn_buffer[{init_add + 6 + i*10}] = {np.uint16(struct[5]) & 0x00FF};') # of_offset
        a[i*11 + 8] = (np.uint16(struct[5]) >> 8) & 0x00FF
        #print(f'rn_buffer[{init_add + 7 + i*10}] = {(np.uint16(struct[5]) >> 8) & 0x00FF};')

        a[i*11 + 9] = struct[6]
        #print(f'rn_buffer[{init_add + 8 + i*10}] = {struct[6]};') # n

        a[i*11 + 10] = struct[7]
        #print(f'rn_buffer[{init_add + 9 + i*10}] = {struct[7]};') # frac

        #print('// ########')

    rn_bufferFC_init(a)

def rn_bufferFC_init(a):
    a = a.astype(np.int8)
    with open('sim/rn_bufferFC_init.mem', 'w') as f:
        for i in range(a.shape[0]):
            if a[i] < 0:
                positive_value = a[i] & 0xFF
                f.write(format(positive_value, '02x') + '\n')
            else:
                f.write(format(a[i], '02x') + '\n')


def convert_model(ifmap, cnn_layers_amount, fc_layers_amount, model, interpreter):

    weights = model.get_weights()
    cnn_quant_params = []
    dense_quant_params = []
    keys = ['b_scale', 'w_scale']

    tensor_details = interpreter.get_tensor_details()
    off1 = 2
    for i in np.arange(0, int(fc_layers_amount*2), step=2):
        dense_quant_params.append({keys[j]: tensor_details[off1 + i + j]['quantization_parameters']['scales'] for j in range(2)})
    
    off2 = off1 + int(fc_layers_amount*2)
    for i in np.arange(0, int(cnn_layers_amount*2), step=2):
        cnn_quant_params.append({keys[j]: tensor_details[off2 + i + j]['quantization_parameters']['scales'] for j in range(2)})

    dense_quant_params.reverse()
    cnn_quant_params.reverse()
    off3 = off2 + int(cnn_layers_amount*2)
    for i in np.arange(0, int(cnn_layers_amount), step=1):
        cnn_quant_params[i]['out_scale'] = tensor_details[off3 + i]['quantization_parameters']['scales']

    off4 = off3 + 1 + int(cnn_layers_amount)

    for i in np.arange(0, int(fc_layers_amount), step=1):
        dense_quant_params[i]['out_scale'] = tensor_details[off4 + i]['quantization_parameters']['scales']

    cnn_weights = weights[0:int(cnn_layers_amount*2)]
    fc_weights = weights[int(cnn_layers_amount*2):int(cnn_layers_amount*2 + fc_layers_amount*2)]

    q_cnn_weights = []
    q_cnn_bias = []
    n_frac_cnn = []

    q_fc_weights = []
    q_fc_bias = []
    n_frac_fc = []    

    input_rescale = tensor_details[0]['quantization_parameters']['scales']

    for i, cnn_quant_param in enumerate(cnn_quant_params):
        q_cnn_weights.append(cnn_weights[i*2] / cnn_quant_param['w_scale'])
        q_cnn_bias.append(cnn_weights[i*2 + 1] / cnn_quant_param['b_scale'])
        for j in range(cnn_quant_param['w_scale'].shape[0]):
            n_frac_cnn.append(get_M_shifter(cnn_quant_param['w_scale'][j] * input_rescale / cnn_quant_param['out_scale']))
        input_rescale = cnn_quant_param['out_scale']

    for i, dense_quant_param in enumerate(dense_quant_params):
        q_fc_weights.append(fc_weights[i*2] / dense_quant_param['w_scale'])
        q_fc_bias.append(fc_weights[i*2 + 1] / dense_quant_param['b_scale'])
        n_frac_fc.append(get_M_shifter(dense_quant_param['w_scale'] * input_rescale / dense_quant_param['out_scale']))
        input_rescale = dense_quant_param['out_scale']

    
    gen_weight_map_cnn(q_cnn_weights)
    gen_bias_map_cnn(q_cnn_bias)
    gen_n_frac_map_cnn(n_frac_cnn)
 
    structs = []
    if_size = ifmap.shape[0]
    for i in range(cnn_layers_amount):
        tmp = []
        if i == cnn_layers_amount-1:
            tmp.append(1)
        else:
            tmp.append(0)
        
        tmp.append(cnn_weights[i*2].shape[2]) # amount channels
        tmp.append(3) # kernel size
        tmp.append(1) # stride
        tmp.append(if_size) # if_size
        tmp.append(3**2) # kernel size 2
        tmp.append(if_size**2)
        tmp.append(cnn_weights[i*2].shape[3]) # amount filters
        tmp.append(if_size-2) # of size
        tmp.append((if_size-2)**2)
        tmp.append(if_size**2*cnn_weights[i*2].shape[2]) # of offset

        if_size = if_size-2
        structs.append(tmp)
#####
        # last_stage
        # amount_channels
        # kernel_size
        # stride
        # if_size
        # kernel_size_2
        # ifsize_2
        # amount_filters
        # of_size
        # ofsize_2
        # of_offset
#####

    gen_cnn_struct(structs, 0)

    channels_last_cnn = 3
    gen_weight_map_fc(q_fc_weights, channels_last_cnn=channels_last_cnn)
    gen_bias_map_fc(q_fc_bias)
    
    structs = []
    if_size = ifmap.shape[0]
    for i in range(fc_layers_amount):
        tmp = []

        tmp.append(fc_weights[i*2].shape[0]) # cant inputs
        tmp.append(np.ceil(fc_weights[i*2].shape[0]/6)) # iters per neuron
        tmp.append(np.ceil(fc_weights[i*2].shape[0]/6)*6 - fc_weights[i*2].shape[0]) # modulo
        tmp.append(fc_weights[i*2 + 1].shape[0]) # cant neurons
        if i == fc_layers_amount-1:
            tmp.append(1)
        else:
            tmp.append(0)

        tmp.append(fc_weights[i*2].shape[0]) # of offset

        tmp.append(n_frac_fc[i][0]) # n
        tmp.append(n_frac_fc[i][1]) # frac

        structs.append(tmp)
        
#####
        # cant_inputs
        # iters_per_neuron
        # modulo
        # cant_neurons
        # last
        # of_offset
        # n
        # frac
#####

    gen_fc_struct(structs, 0)
    mem_init(ifmap/tensor_details[0]['quantization_parameters']['scales'])

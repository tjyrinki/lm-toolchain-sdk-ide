#!/bin/bash

if [ -z "$CRED_KEY" ]; then
    echo "Cred Key not set, using a dummy key"
    CRED_KEY="0xeafbf3cd57d7081f"
else
    echo "Using Cred Key from environment"
fi  

if [ -z "$CRED_FILE" ]; then
    echo "Cred file not set, creating cred_key.h in ${PWD}"
    CRED_FILE="cred_key.h"
else
    echo "Cred file created in: ${CRED_FILE}"
fi  

cat << EOF > ${CRED_FILE}
#ifndef LM_CRED_KEY_H
#define LM_CRED_KEY_H

#include <qglobal.h>

namespace LmBase {
namespace Constants {

const quint64 LM_CREDENTIALS = Q_UINT64_C(${CRED_KEY});

}}

#endif
EOF
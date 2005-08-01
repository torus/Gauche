//
// mqueue_glue.h
//
//   The mqueue-cpp extension module to show how to embed external C++
//   library in Gauche.
//   This file works as a 'glue' between the external C++ library
//   (mqueue.h, mqueue.cpp) and Gauche extension.  If you're writing
//   a bridge for the third party C++ library, the contents of this
//   file is the stuff you're supposed to write.
//

#include "mqueue.h"

#include <gauche.h>
#include <gauche/extend.h>

SCM_DECL_BEGIN   // start "C" linkage

extern ScmClass *MQueueClass;

#define MQUEUE_P(obj)      SCM_XTYPEP(obj, MQueueClass)
#define MQUEUE_UNBOX(obj)  ((MQueue*)(SCM_FOREIGN_POINTER_REF(obj)))
#define MQUEUE_BOX(ptr)    Scm_MakeForeignPointer(MQueueClass, ptr)

extern void Scm_Init_mqueue_cpp();

SCM_DECL_END



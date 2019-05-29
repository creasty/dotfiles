import re
import vim

def format(snip, operand, op):
    trailing_space = ''

    trailing_space_m = re.search(r'\s+$', op)
    if trailing_space_m:
        trailing_space = trailing_space_m.group(0)
        op = op[:-len(trailing_space)]

    if re.match(r'^\?(?!\?)|!(?!!)', op):
        # a suffix operator: `operand?` `operand!`
        operand += op[0]
        op = op[1:]

    # 0: no spacing
    # 1: space left
    # 2: space around
    separation = 1 if len(op) > 0 and op[0] == ' ' else 0
    op = op.replace(' ', '')

    if op == '':
        pass
    elif op == ':':
        pass
    elif operand in {'(', '[', '{'}:
        separation = 0 # the beginning of expression
    elif op == '++' and separation > 0:
        separation = 0 # a suffix operator: operand++
    elif op == '--' and separation > 0:
        separation = 0 # a suffix operator: operand--
    elif op == '+++' and separation == 0:
        op = '++'
        separation = 2 # convert to an infix operator: operand ++ operand
    elif op == '---' and separation == 0:
        op = '--'
        separation = 2 # convert to an infix operator: operand -- operand
    else:
        separation = 2

    op = re.sub(r'([=]+)', r' \1 ', op) # group equals
    op = re.sub(r'([!]) = ', r' \1= ', op) # compound comparators (left)
    op = re.sub(r' = ([~])', r' =\1 ', op) # compound comparators (right)
    op = re.sub(r' (!=|==) ([#])', r' \1\2 ', op) # comparators with modifier
    op = re.sub(r'(?:^| )([\+\-\*/%\^~:]|([\|&\?])\2?|<<|>>) = ', r' \1= ', op) # compound assignment operators

    op = op.strip()

    if separation > 0:
        op = ' ' + op
    if separation > 1 and len(trailing_space) == 0:
        op += ' '

    return operand + op + trailing_space

def get_syntax_names(l, c):
    try:
        syntax_stack = vim.eval('synstack({}, {})'.format(l + 1, c + 1))
    except:
        return []

    names = []
    for syn_id in syntax_stack:
        names.append(vim.eval('synIDattr(synIDtrans({}), "name")'.format(syn_id)))

    return names

def get_syntactical_context(l, c):
    names = get_syntax_names(l, c)

    for name in names:
        if re.search('reg(ular)?ex', name, re.IGNORECASE):
            return 'regexp'
        elif re.search('htmltag|jsxelement', name, re.IGNORECASE):
            return 'tag'
        elif re.search('string', name, re.IGNORECASE):
            return 'string'

    return None

def get_last_separation_style(text, column, op):
    if column == 0:
        return -1

    if text[column] != op:
        return -1

    pos = text.rfind(op, 0, column)
    if pos == -1:
        return -1

    l = text[pos - 1] if pos > 0 else ''
    r = text[pos + 1] if pos < column else ''

    if l == op:
        return -1

    if l == ' ':
        if r == ' ':
            return 2
        else:
            return 1
    else:
        return 0

def context(snip):
    text = snip.buffer[snip.line]

    if text[snip.column] == ' ':
        return None

    if get_last_separation_style(text, snip.column, '-') == 0:
        return None # Handles kebab-case

    if get_syntactical_context(snip.line, snip.column):
        return None

    return {"space_op": True}
